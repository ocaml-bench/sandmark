#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+multicore.bench
RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+multicore+mimalloc.bench

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock+bestfit80.bench
RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock+bestfit100.bench
RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+stock+bestfit120.bench
