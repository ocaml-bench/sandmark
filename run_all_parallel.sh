#!/bin/bash

# If using RUN_BENCH_TARGET=run_orunchrt the parallel benchmarks
# use `chrt -r 1`. You may need to setup permissions to allow the
# user to execute `chrt`. For example, this could be done with:
#   sudo setcap cap_sys_nice=ep /usr/bin/chrt
#

TAG='"macro_bench"' make multicore_parallel_run_config_filtered.json

START_TIME=$(date +%s)

if [ "$1" = "--wait" ]; then
    OPT_WAIT=1
else 
    OPT_WAIT=0
fi


USE_SYS_DUNE_HACK=1 \
                 RUN_BENCH_TARGET=run_orunchrt \
                 BUILD_BENCH_TARGET=multibench_parallel \
                 RUN_CONFIG_JSON=multicore_parallel_run_config_filtered.json \
                 make OPT_WAIT=$OPT_WAIT START_TIME=$START_TIME ocaml-versions/5.0.0+stable.bench
