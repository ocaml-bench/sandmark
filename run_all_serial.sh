#!/bin/bash

make run_config_macro.json

RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.10.0+stock.bench
RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.10.0+multicore.bench
RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.10.0+multicore+redzone0.bench
RUN_CONFIG_JSON=run_config_macro.json make ocaml-versions/4.10.0+multicore+redzone32.bench
