#!/bin/bash


BUILD_BENCH_TARGET=multibench_effects \
	RUN_CONFIG_JSON=multicore_effects_run_config.json \
	make ocaml-versions/4.12.0+domains+effects.bench
