#!/bin/bash

TAG='"run_in_ci"' make run_config_filtered.json

RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.14.0+trunk.bench
