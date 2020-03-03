#!/bin/bash

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


