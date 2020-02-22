#!/bin/bash

# Run `make multicore_parllel_run_config_macro.json` before running this script.

RUN_BENCH_TARGET=run_pausetimes_multicore BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+parallel.bench
RUN_BENCH_TARGET=run_pausetimes_multicore BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+stw+parallel.bench

BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+parallel.bench
BUILD_BENCH_TARGET=multibench_parallel \
	RUN_CONFIG_JSON=multicore_parallel_run_config_macro.json \
	make ocaml-versions/4.06.1+multicore+stw+parallel.bench


