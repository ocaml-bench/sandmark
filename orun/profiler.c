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

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>

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
    uint64_t ip;          /* if PERF_SAMPLE_IP */
    uint64_t time;        /* if PERF_SAMPLE_TIME */
    uint64_t bnr;         /* if PERF_SAMPLE_BRANCH_STACK */
};

long perf_event_open(struct perf_event_attr *hw_event, pid_t pid,
                     int cpu, int group_fd, unsigned long flags)
{
    int ret;

    ret = syscall(__NR_perf_event_open, hw_event, pid, cpu,
                  group_fd, flags);
    return ret;
}

void handle_signal(int sig) {}

ssize_t write_or_bail(int fd, const void *buf, size_t count)
{
    int written = 0;
    int n;
    while (written < count)
    {
        if ((n = write(fd, buf + written, count - written)) < 0)
        {
            if (errno == EINTR || errno == EAGAIN)
            {
                continue;
            }
            perror("write");
            exit(-1);
        }

        written += n;
    }
}

int poll_event(int fd)
{
    struct pollfd pfd = {.fd = fd, .events = POLLIN };

    int ret = poll(&pfd, 1, 1000);

    return pfd.revents;
}

int read_event(uint32_t type, void *buf)
{
    if (type == PERF_RECORD_MMAP)
    {
        printf("got mmap record\n");
    }

    if (type == PERF_RECORD_MMAP2)
    {
        struct perf_event_record_mmap2 *record = buf;
        printf("got mmap2 record: %s\n", record->filename);
    }

    if (type == PERF_RECORD_EXIT)
    {
        printf("got process exit\n");
        return 0;
    }

    if (type == PERF_RECORD_SAMPLE)
    {
        struct perf_event_record_sample *record = buf;

        unsigned char* pos = buf + sizeof(struct perf_event_record_sample);

        printf("ip: %lu, branches: %lu\n", record->ip, record->bnr);

        for( int branches = 0; branches < record->bnr ; branches++ ) {
            struct perf_branch_entry* entry = (struct perf_branch_entry*)pos;

            printf("%d ip: %llu -> %llu (%d) [%u]\n", branches, entry->from, entry->to, entry->cycles, entry->mispred);

            pos += sizeof(struct perf_branch_entry);
        }
    }

    return 1;
}

int main(int argc, char *argv[])
{
    pid_t pid = fork();

    signal(SIGCONT, &handle_signal);

    if (pid == 0)
    {
        pause();
        int ret = execvp(argv[1], &argv[1]);

        if (ret == -1)
        {
            perror("exec");
        }
    }
    else
    {
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

        /*
        pe.freq = 1;
        pe.comm = 1;
        pe.comm_exec = 1;
        
        pe.task = 1;

        pe.precise_ip = 3;
        pe.inherit = 1;
        pe.sample_freq = 1000;
        pe.disabled = 1;
*/
        /*      pe.watermark = 1;
        pe.wakeup_watermark = DATA_PAGES / (4 * page_size);*/

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

        kill(pid, SIGCONT);

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

                int status = read_event(event_header->type, &buffer);

                if( status == 0 ) {
                    return 0; // Succes
                }
            }
            else
            {
                // Fast path, can just hand the memory straight from the ring
                int status = read_event(event_header->type, data + tail);

                if( status == 0 ) {
                    return 0; // Succes
                }
            }

            data_read += event_header->size;

            printf("type: %u, size: %u, read: %lu\n", event_header->type, event_header->size, data_read);

            // write_or_bail(perf_data_fd, data + tail, event_header->size);

            __atomic_store_n(&header->data_tail, original_tail + event_header->size, __ATOMIC_RELEASE);
        }

        close(perf_fd);
        munmap(base, (1 + DATA_PAGES) * page_size);
        fsync(perf_data_fd);
        close(perf_data_fd);
    }
}
