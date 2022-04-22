#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

OPT_WAIT=0 USE_SYS_DUNE_HACK=1 RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/5.0.0+stable.bench
