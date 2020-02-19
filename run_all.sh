#!/bin/bash

# Serial pausetime numbers: these instrumented compilers should not be considered for throughput
RUN_BENCH_TARGET=run_pausetimes_trunk RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.11.0+trunk+instrumented.bench
# `pausetimes_trunk` sets OCAMLRUNPARAM="O=1000000,a=2"
RUN_BENCH_TARGET=run_pausetimes_multicore RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore+pausetimes.bench
RUN_BENCH_TARGET=run_pausetimes_multicore RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore+stw+pausetimes.bench

# Serial run time numbers (all the stats: time_real, major_works, major_collections, etc)
OCAMLRUNPARAM="O=1000000,a=2" RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.11.0+trunk.bench
RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore.bench
RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.06.1+multicore+stw.bench
