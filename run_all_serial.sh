#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

START_TIME=$(date +%s)

if [ "$1" = "--wait" ]; then
    OPT_WAIT=1
else 
    OPT_WAIT=0
fi

USE_SYS_DUNE_HACK=1 RUN_CONFIG_JSON=run_config_filtered.json make OPT_WAIT=$OPT_WAIT START_TIME=$START_TIME ocaml-versions/5.0.0+stable.bench
