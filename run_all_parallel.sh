#!/bin/bash

# Since the parallel benchmarks use `chrt -r 1` you will need to run this script
# twice. First run without sudo which will build the compiler and the benchmarks,
# and will fail running the benchmarks. Then run the script with sudo which will
# run the benchmarks and produce the results.
#
# $ bash run_all_parallel.sh; sudo bash run_all_parallel.sh

make multicore_parallel_run_config_macro.json

RUN_BENCH_TARGET=run_pausetimes_multicore BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+pausetimes+parallel.bench
RUN_BENCH_TARGET=run_pausetimes_multicore BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+stw+pausetimes+parallel.bench

BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+parallel.bench
BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+stw+parallel.bench
