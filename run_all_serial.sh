#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

RUN_BENCH_TARGET=run_orun_bf80 RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock.bench
RUN_BENCH_TARGET=run_orun_bf100 RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock.bench
RUN_BENCH_TARGET=run_orun_bf120 RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock.bench

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+multicore.bench
RUN_BENCH_TARGET=run_orun_mimalloc RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+multicore.bench
