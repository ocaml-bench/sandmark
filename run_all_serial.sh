#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+multicore.bench
RUN_BENCH_TARGET=run_pausetimes_multicore RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+multicore+pausetimes.bench

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock.bench
RUN_BENCH_TARGET=run_pausetimes_trunk RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock+instrumented.bench
