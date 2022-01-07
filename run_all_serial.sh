#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/5.00.0+trunk.bench
RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/5.00.0+domains.bench
