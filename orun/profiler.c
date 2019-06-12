#define _GNU_SOURCE
#include <linux/perf_event.h>
#include <linux/hw_breakpoint.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <linux/perf_event.h>
#include <asm/unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <stdint.h>
#include <err.h>
#include <sys/stat.h>
#include <poll.h>
#include <fcntl.h>
#include <elfutils/libdwfl.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

#define DATA_PAGES 1024
#define INITIAL_LIST_LENGTH 512

struct sample_id
{
    uint32_t pid;
    uint32_t tid;
    uint64_t time;
};

struct perf_event_record_mmap2
{
    struct perf_event_header header;
    uint32_t pid;
    uint32_t tid;
    uint64_t addr;
    uint64_t len;
    uint64_t pgoff;
    uint32_t maj;
    uint32_t min;
    uint64_t ino;
    uint64_t ino_generation;
    uint32_t prot;
    uint32_t flags;
    char filename[];
};

struct read_format
{
    uint64_t value;        /* The value of the event */
    uint64_t time_enabled; /* if PERF_FORMAT_TOTAL_TIME_ENABLED */
    uint64_t time_running; /* if PERF_FORMAT_TOTAL_TIME_RUNNING */
    uint64_t id;           /* if PERF_FORMAT_ID */
};

struct perf_event_record_sample
{
    struct perf_event_header header;
    uint64_t ip;   /* if PERF_SAMPLE_IP */
    uint64_t time; /* if PERF_SAMPLE_TIME */
    uint64_t bnr;  /* if PERF_SAMPLE_BRANCH_STACK */
};

struct ip_list
{
    uint64_t *ips;
    uint64_t length;
    uint64_t pos;
};

struct mmap_node {
    char* filename;
    uint64_t addr;
    uint64_t length;
    struct mmap_node* next;
};

void append_to_list( struct ip_list* list, uint64_t ip ) {
    if( list->pos == list->length ) {
        // Need to double the size of the list and copy the contents across
        uint64_t* new_ips = malloc( (list->length*2) * sizeof(uint64_t) );

        if( new_ips == NULL ) {
            perror("malloc");
            exit(-1);
        }
        
        memcpy( new_ips, list->ips, list->length * sizeof(uint64_t) );
        uint64_t* old_ips = list->ips;
        list->ips = new_ips;
        free(old_ips);
        list->length *= 2;
    }

    list->ips[list->pos++] = ip;

    return;
}

long perf_event_open(struct perf_event_attr *hw_event, pid_t pid,
                     int cpu, int group_fd, unsigned long flags)
{
    int ret;

    ret = syscall(__NR_perf_event_open, hw_event, pid, cpu,
                  group_fd, flags);
    return ret;
}

int poll_event(int fd)
{
    struct pollfd pfd = {.fd = fd, .events = POLLIN};

    int ret = poll(&pfd, 1, 1000);

    return pfd.revents;
}

int read_event(uint32_t type, void *buf, struct ip_list* ips, struct mmap_node** head_ptr)
{
    if (type == PERF_RECORD_MMAP)
    {
        printf("got mmap record\n");
    }

    if (type == PERF_RECORD_MMAP2)
    {
        struct perf_event_record_mmap2 *record = buf;
        
        struct mmap_node* node = malloc(sizeof(struct mmap_node));

        node->filename = malloc(sizeof(record->filename[0]) * (strlen(record->filename)+1));

        strcpy(node->filename, record->filename);

        node->addr = record->addr;
        node->length = record->len;

        if( head_ptr != NULL ) {
            node->next = *head_ptr;
        } else {
            node->next = NULL;
        }

        *head_ptr = node;
    }

    if (type == PERF_RECORD_EXIT)
    {
        printf("got process exit\n");
        return 0;
    }

    if (type == PERF_RECORD_SAMPLE)
    {
        struct perf_event_record_sample *record = buf;

        unsigned char *pos = buf + sizeof(struct perf_event_record_sample);

        append_to_list(ips, record->ip);

        //printf("ip: %lu, branches: %lu\n", record->ip, record->bnr);
/*
        for (int branches = 0; branches < record->bnr; branches++)
        {
            struct perf_branch_entry *entry = (struct perf_branch_entry *)pos;

            printf("%d ip: %llu -> %llu (%d) [%u]\n", branches, entry->from, entry->to, entry->cycles, entry->mispred);

            pos += sizeof(struct perf_branch_entry);
        }*/
    }

    return 1;
}

void lookup_dwarf_data(struct mmap_node* head_ptr, struct ip_list* ips) {
    static char *debuginfo_path;

    static const Dwfl_Callbacks offline_callbacks =
    {
        .find_debuginfo = dwfl_standard_find_debuginfo,
        .debuginfo_path = &debuginfo_path,
        .section_address = dwfl_offline_section_address,
        .find_elf = dwfl_build_id_find_elf,
    };

    struct Dwfl* dwfl = dwfl_begin(&offline_callbacks);

    struct mmap_node* curr = head_ptr;

    while( curr != NULL ) {
        struct Dwfl_module* module = dwfl_report_elf(dwfl, curr->filename, curr->filename, -1, curr->addr, false);

        curr = curr->next;
    }

    dwfl_report_end(dwfl, NULL, NULL);

    for( int x = 0; x < ips->pos; x++ ) {
        uint64_t ip = ips->ips[x];

        Dwfl_Line* line = dwfl_getsrc(dwfl, ip);

        if( line != NULL ) {
            printf("Found line for %lu\n", ip);
            Dwfl_Module* module = dwfl_linemodule(line);
            int lineno;

            char* filename = dwfl_lineinfo(line, NULL, &lineno, NULL, NULL, NULL);

            if( filename != NULL ) {
                printf("\t%s:%d\n", filename, lineno);
            }
        } else {
            printf("Could not find line for %lu\n", ip);
        }
    }

    dwfl_end(dwfl);
}

value ml_unpause_and_start_profiling(value ml_pid)
{
    CAMLparam1(ml_pid);
    CAMLlocal4(result,mmap_entries,ips,entry);

    struct ip_list* list = malloc(sizeof(struct ip_list));
    list->ips = malloc(INITIAL_LIST_LENGTH * sizeof(uint64_t));

    if( list->ips == NULL ) {
        perror("malloc");
        exit(-1);
    }

    list->length = INITIAL_LIST_LENGTH;
    list->pos = 0;

    struct mmap_node* head_ptr = NULL;

    pid_t pid = Long_val(ml_pid);

    struct perf_event_attr pe;
    int perf_fd;
    struct perf_event_mmap_page *header;
    void *base, *data;
    int page_size = getpagesize();

    memset(&pe, 0, sizeof(struct perf_event_attr));

    pe.type = 0;
    pe.size = sizeof(pe);
    pe.sample_type = PERF_SAMPLE_IP | PERF_SAMPLE_TIME | PERF_SAMPLE_BRANCH_STACK;
    pe.branch_sample_type = PERF_SAMPLE_BRANCH_USER | PERF_SAMPLE_BRANCH_ANY;
    pe.sample_freq = 1000;
    pe.freq = 1;
    pe.exclude_kernel = 1;
    pe.exclude_hv = 1;
    pe.exclude_guest = 1;
    pe.enable_on_exec = 1;
    pe.disabled = 1;
    pe.task = 1;
    pe.mmap = 1;
    pe.mmap2 = 1;

    perf_fd = perf_event_open(&pe, pid, -1, -1, 0);

    if (perf_fd < 0)
    {
        perror("perf_event_open");
        return -1;
    }

    int perf_data_fd = open("perf-main.out", O_CREAT | O_WRONLY | O_TRUNC, S_IRUSR | S_IWUSR);

    if (perf_data_fd < 0)
    {
        perror("open");
        return -1;
    }

    uint64_t mmap_size = (1 + DATA_PAGES) * page_size;
    base = mmap(NULL, mmap_size, PROT_READ | PROT_WRITE, MAP_SHARED, perf_fd, 0);

    if (base == MAP_FAILED)
    {
        printf("mmap failed: %d\n", perf_fd);
        err(EXIT_FAILURE, "mmap");
    }

    header = base;
    data = base + header->data_offset;

    kill(pid, SIGUSR1);

    uint64_t data_read = 0;

    while (1)
    {
        uint64_t original_tail = header->data_tail;
        uint64_t tail = original_tail;
        uint64_t original_head = __atomic_load_n(&header->data_head, __ATOMIC_ACQUIRE);
        uint64_t head = original_head;

        if ((head - tail) % header->data_size == 0)
        {
            // Ring buffer is empty, let's wait for something interesting to happen
            // int revents = poll_event(perf_fd);

            // Right, time to go check things again
            continue;
        }

        head = head % header->data_size;
        tail = tail % header->data_size;

        struct perf_event_header *event_header = (data + tail);

        int space_left_in_ring = header->data_size - (tail + event_header->size);

        if (space_left_in_ring < 0)
        {
            // Slow path, need to copy the data out first
            unsigned char buffer[event_header->size];

            int remaining = header->data_size - tail;

            memcpy(buffer, data + tail, remaining);
            memcpy(buffer + remaining, data, event_header->size - remaining);

            int status = read_event(event_header->type, &buffer, list, &head_ptr);

            if (status == 0)
            {
                break; // Succes
            }
        }
        else
        {
            // Fast path, can just hand the memory straight from the ring
            int status = read_event(event_header->type, data + tail, list, &head_ptr);

            if (status == 0)
            {
                break; // Success
            }
        }

        data_read += event_header->size;

        __atomic_store_n(&header->data_tail, original_tail + event_header->size, __ATOMIC_RELEASE);
    }

    close(perf_fd);
    munmap(base, (1 + DATA_PAGES) * page_size);
    fsync(perf_data_fd);
    close(perf_data_fd);

    struct mmap_node *curr = head_ptr, *tmp, *prev = NULL, *next;

    // reverse our linked list
    while( curr != NULL ) {
        next = curr->next;
        curr->next = prev;
        prev = curr;
        curr = next;
    }

    head_ptr = prev;

    lookup_dwarf_data(head_ptr, list);

    /*for( int x = 0; x < list->pos; x++ ) {
        uint64_t ip = list->ips[x];

        // Look up in linked list of executables
        curr = head_ptr;
        int found = 0;
        struct mmap_node* found_node = NULL;
        while( curr != NULL && !found ) {
            if( ip >= curr->addr && ip < (curr->addr+curr->length) ) {
                found = 1;
                found_node = curr;
            }
            curr = curr->next;
        }

        if( found ) {
            printf("found %lu in %s at %lu\n", ip, found_node->filename, (ip - curr->addr));
        } else {
            printf("could not find %lu\n", ip);
        }
    }*/

    curr = head_ptr;
    while( curr != NULL ) {
        tmp = curr;
        curr = curr->next;
        free(tmp->filename);
        free(tmp);
    }

    // For each ip in the list, figure out which executable it maps to


    printf("returning to ocaml\n");

    CAMLreturn( result );
}
