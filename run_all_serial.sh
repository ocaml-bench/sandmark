#!/bin/bash

TAG='"macro_bench"' make sequential_filtered.json

USE_SYS_DUNE_HACK=1 RUN_CONFIG_JSON=sequential_filtered.json make ocaml-versions/5.0.0+stable.bench
