#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

USE_SYS_DUNE_HACK=1 RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/5.00.0+stable.bench
