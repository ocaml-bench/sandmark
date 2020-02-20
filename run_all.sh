#!/bin/bash

# Run `make run_config_macro.json` before running this script.

RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore.bench
RUN_BENCH_TARGET=run_pausetimes_multicore RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore+pausetimes.bench

RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore+stw.bench
RUN_BENCH_TARGET=run_pausetimes_multicore RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore+stw+pausetimes.bench

RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+stock.bench
RUN_BENCH_TARGET=run_pausetimes_trunk RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+stock+instrumented.bench
