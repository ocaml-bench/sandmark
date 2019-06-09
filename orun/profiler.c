#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>
#include <caml/callback.h>

#ifdef __linux__
#include <linux/perf_event.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <stdio.h>
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
#include <limits.h>

#define DATA_PAGES 1024

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
    uint32_t pid;  /* if PERF_SAMPLE_TID */
    uint32_t tid;  /* if PERF_SAMPLE_TID */
    uint64_t time; /* if PERF_SAMPLE_TIME */
    uint32_t cpu;  /* if PERF_SAMPLE_CPU */
    uint32_t res;  /* if PERF_SAMPLE_CPU */
    uint64_t bnr;  /* if PERF_SAMPLE_CALLCHAIN */
};

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
    struct pollfd pfd = {.fd = fd, .events = POLLIN | POLLHUP};

    int ret = poll(&pfd, 1, 1000);

    return pfd.revents;
}

value some(value contents)
{
    CAMLparam1(contents);
    CAMLlocal1(option);

    option = caml_alloc(1, 0);

    Store_field(option, 0, contents);

    CAMLreturn(option);
}

int get_line_info(Dwfl *dwfl, uint64_t ip, const char **ip_filename, const char **ip_comp_dir, const char **ip_function_name, Dwarf_Addr *addr, int *ip_lineno)
{
    Dwfl_Module *module = dwfl_addrmodule(dwfl, ip);

    dwfl_module_relocate_address(module, addr);

    *ip_function_name = dwfl_module_addrname(module, ip);

    Dwfl_Line *line = dwfl_getsrc(dwfl, ip);

    if (line != NULL)
    {
        const char *filename = dwfl_lineinfo(line, NULL, ip_lineno, NULL, NULL, NULL);

        if (filename != NULL)
        {
            const char *comp_dir = dwfl_line_comp_dir(line);

            *ip_filename = filename;
            *ip_comp_dir = comp_dir;
        }
    }
}

value get_source_line_for_ip(Dwfl *dwfl, uint64_t ip)
{
    CAMLparam0();
    CAMLlocal1(source_line_record);

    const char *filename = NULL;
    const char *comp_dir = NULL;
    const char *function_name = NULL;
    int lineno = -1;

    Dwarf_Addr addr = ip;

    get_line_info(dwfl, ip, &filename, &comp_dir, &function_name, &addr, &lineno);

    source_line_record = caml_alloc(5, 0);

    if (function_name != NULL)
    {
        Store_field(source_line_record, 1, some(caml_copy_string(function_name)));
    }
    else
    {
        Store_field(source_line_record, 1, Val_unit);
    }

    if (filename != NULL)
    {
        int filename_length = strlen(filename);

        char *resolved_path = NULL;

        if (filename_length > 0 && filename[0] != '/' && comp_dir != NULL)
        {
            char full_path[filename_length + strlen(comp_dir) + 2];

            strcpy(full_path, comp_dir);
            strcat(full_path, "/");
            strcat(full_path, filename);

            resolved_path = realpath(full_path, NULL);

            if (resolved_path == NULL)
            {
                Store_field(source_line_record, 0, some(caml_copy_string(full_path)));
            }
            else
            {
                Store_field(source_line_record, 0, some(caml_copy_string(resolved_path)));
                free(resolved_path);
            }
        }
        else
        {
            resolved_path = realpath(filename, NULL);

            if (resolved_path == NULL)
            {
                Store_field(source_line_record, 0, some(caml_copy_string(filename)));
            }
            else
            {
                Store_field(source_line_record, 0, some(caml_copy_string(resolved_path)));
                free(resolved_path);
            }
        }
    }
    else
    {
        Store_field(source_line_record, 0, Val_unit);
    }

    Store_field(source_line_record, 2, Val_int(lineno));
    Store_field(source_line_record, 3, Val_int(addr));

    CAMLreturn(source_line_record);

    CAMLreturn(Val_unit);
}

int read_event(uint32_t type, unsigned char *buf, value sample_callback, Dwfl *dwfl, pid_t child_pid, int *sample_id)
{
    CAMLparam1(sample_callback);
    CAMLlocal5(sample_record, branches_head, branches_entry, source_line_option, callback_return);

    if (type == PERF_RECORD_MMAP2)
    {
        struct perf_event_record_mmap2 *record = (struct perf_event_record_mmap2 *)buf;

        dwfl_report_begin_add(dwfl);

        Dwfl_Module *module = dwfl_report_elf(dwfl, (const char *)record->filename, (const char *)record->filename, -1, record->addr - record->pgoff, false);

        dwfl_report_end(dwfl, NULL, NULL);
    }
    else if (type == PERF_RECORD_EXIT)
    {
        CAMLdrop;
        return 0;
    }
    else if (type == PERF_RECORD_SAMPLE)
    {
        struct perf_event_record_sample *record = (struct perf_event_record_sample *)buf;

        unsigned char *pos = buf + sizeof(struct perf_event_record_sample);

        source_line_option = get_source_line_for_ip(dwfl, record->ip);

        sample_record = caml_alloc(6, 0);
        Store_field(sample_record, 0, source_line_option);

        branches_head = Val_unit;

        // walk branch stack now and add these
        uint64_t branches = record->bnr;

        for (int c = 0; c < branches; c++)
        {
            struct perf_branch_entry *entry = (struct perf_branch_entry *)pos;

            uint64_t from_ip = entry->from;

            source_line_option = get_source_line_for_ip(dwfl, from_ip);

            branches_entry = caml_alloc(2, 0);

            Store_field(branches_entry, 0, source_line_option);
            Store_field(branches_entry, 1, branches_head);

            branches_head = branches_entry;

            pos += sizeof(struct perf_branch_entry);
        }

        Store_field(sample_record, 1, branches_head);
        Store_field(sample_record, 2, Val_int(record->time));
        Store_field(sample_record, 3, Val_int(record->tid));
        Store_field(sample_record, 4, Val_int(record->cpu));
        Store_field(sample_record, 5, Val_int(*sample_id));

        (*sample_id)++;

        callback_return = caml_callback(sample_callback, sample_record);
    }

    CAMLdrop;
    return 1;
}

value ml_unpause_and_start_profiling(value ml_pid, value ml_pipe_fds, value sample_callback)
{
    CAMLparam3(ml_pid, ml_pipe_fds, sample_callback);

    int parent_ready_write = Long_val(ml_pipe_fds);

    int sample_id = 0;

    // Set up DWARF stuff
    static char *debuginfo_path;

    static const Dwfl_Callbacks offline_callbacks =
        {
            .find_debuginfo = dwfl_standard_find_debuginfo,
            .debuginfo_path = &debuginfo_path,
            .section_address = dwfl_offline_section_address,
            .find_elf = dwfl_build_id_find_elf,
        };

    struct Dwfl *dwfl = dwfl_begin(&offline_callbacks);

    struct mmap_node *head_ptr = NULL;

    pid_t pid = Long_val(ml_pid);

    struct perf_event_attr pe;
    int perf_fd;
    struct perf_event_mmap_page *header;
    unsigned char *base, *data;
    int page_size = getpagesize();

    memset(&pe, 0, sizeof(struct perf_event_attr));

    pe.type = 0;
    pe.size = sizeof(pe);
    pe.sample_type = PERF_SAMPLE_IP | PERF_SAMPLE_TIME | PERF_SAMPLE_CPU | PERF_SAMPLE_TID | PERF_SAMPLE_BRANCH_STACK;
    pe.branch_sample_type = PERF_SAMPLE_BRANCH_USER | PERF_SAMPLE_BRANCH_CALL_STACK;
    pe.sample_freq = 3000;
    pe.freq = 1;
    pe.exclude_kernel = 1;
    pe.exclude_hv = 1;
    pe.exclude_guest = 1;
    pe.enable_on_exec = 1;
    pe.disabled = 1;
    pe.task = 1;
    pe.mmap = 1;
    pe.mmap2 = 1;
    pe.wakeup_events = 1;

    perf_fd = perf_event_open(&pe, pid, -1, -1, 0);

    if (perf_fd < 0)
    {
        perror("perf_event_open");
        return -1;
    }

    uint64_t mmap_size = (1 + DATA_PAGES) * page_size;
    base = mmap(NULL, mmap_size, PROT_READ | PROT_WRITE, MAP_SHARED, perf_fd, 0);

    if (base == MAP_FAILED)
    {
        printf("mmap failed: %d\n", perf_fd);
        err(EXIT_FAILURE, "mmap");
    }

    header = (struct perf_event_mmap_page *)base;
    data = base + header->data_offset;

    // Tell child we're ready
    char *go = "!";

    while (1)
    {
        int ret = write(parent_ready_write, go, 1);

        if (ret < 0)
        {
            if (errno == EAGAIN || errno == EINTR)
            {
                continue;
            }
            else
            {
                perror("write");
                exit(-1);
            }
        }

        break;
    }

    pid_t child_pid = Int_val(ml_pid);
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
            int revents = poll_event(perf_fd);

            if ((revents & POLLHUP) && (__atomic_load_n(&header->data_head, __ATOMIC_ACQUIRE) - tail) % header->data_size == 0)
            {
                break;
            }

            // Right, time to go check things again
            continue;
        }

        head = head % header->data_size;
        tail = tail % header->data_size;

        struct perf_event_header *event_header = (struct perf_event_header *)(data + tail);

        int space_left_in_ring = header->data_size - (tail + event_header->size);

        if (space_left_in_ring < 0)
        {
            // Slow path, need to copy the data out first
            unsigned char buffer[event_header->size];

            int remaining = header->data_size - tail;

            memcpy(buffer, data + tail, remaining);
            memcpy(buffer + remaining, data, event_header->size - remaining);

            int status = read_event(event_header->type, buffer, sample_callback, dwfl, child_pid, &sample_id);

            if (status == 0)
            {
                break; // Success
            }
        }
        else
        {
            // Fast path, can just hand the memory straight from the ring
            int status = read_event(event_header->type, data + tail, sample_callback, dwfl, child_pid, &sample_id);

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

    dwfl_end(dwfl);

    CAMLreturn(Val_unit);
}
#endif

#ifdef __APPLE__
value ml_unpause_and_start_profiling(value ml_pid, value ml_pipe_fds)
{
    CAMLparam2(ml_pid, ml_pipe_fds);

    CAMLreturn(Val_unit);
}
#endif
