#!/bin/bash
# Script called to run the benchmarks, assuming they've been built already.

config_switch_name=$1
build_only=$2
wrapper=$3
run_config_json=$4
pre_bench_exec=$5
iter=$6
run_bench_target=$7
sandmark_custom_name=$8

if $build_only; then
    exit 0;
fi;

echo "Executing benchmarks with:";
echo "  RUN_CONFIG_JSON=$run_config_json";
echo "  RUN_BENCH_TARGET=$run_bench_target  (WRAPPER=$wrapper)";
echo "  PRE_BENCH_EXEC=$pre_bench_exec";
# The big exec is here
$pre_bench_exec opam exec --switch "$config_switch_name" -- dune build -j 1 --profile=release --workspace=ocaml-versions/.workspace."$config_switch_name" @"$run_bench_target"; ex=$?;

metadata () {
    arch=$(uname -m);
    hostname=$(hostname);
    kernel=$(uname -s);
    version=$(uname -r);

    jo arch="$arch" hostname="$hostname" kernel="$kernel" version="$version"
}

mkdir -p _results/;
cp "$run_config_json" _results/;
for i in $(seq 1 "$iter"); do
    metadata > _results/"$sandmark_custom_name"_"$i"."$wrapper".summary.bench;
    find _build/"$config_switch_name"_"$i" -name '*.'"$wrapper"'.bench' -print0 | xargs cat >> _results/"$sandmark_custom_name"_"$i"."$wrapper".summary.bench;
done;
exit "$ex"
