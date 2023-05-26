#!/bin/bash
# Script called to build the benchmarks.

config_switch_name=$1
run_config_json=$2
iter=$3
build_bench_target=$4

fill_dune_file () {
    echo '(lang dune 1.0)';
    for i in $(seq 1 "$iter"); do
        echo "(context (opam (switch $config_switch_name) (name ${config_switch_name}_$i)))";
    done
}

fill_dune_file > ocaml-versions/.workspace."$config_switch_name"
opam exec --switch "$config_switch_name" -- rungen _build/"$config_switch_name"_1 "$run_config_json" > runs_dune.inc
opam exec --switch "$config_switch_name" -- dune build --profile=release --workspace=ocaml-versions/.workspace."$config_switch_name" @"$build_bench_target";