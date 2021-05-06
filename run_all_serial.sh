#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.12.0+stock.bench
RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.12.0+domains.bench
RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.12.0+domains+effects.bench
