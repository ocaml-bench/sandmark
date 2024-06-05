#!/bin/bash

TAG='"macro_bench"' make run_config_filtered.json

OPT_WAIT=0 USE_SYS_DUNE_HACK=0 \
	SANDMARK_CUSTOM_NAME=5.1.0+trunk \
	RUN_CONFIG_JSON=run_config_filtered.json \
	make ocaml-versions/5.1.0+trunk.bench
