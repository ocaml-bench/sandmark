#!/bin/bash
# Script called before we run the benchmarks.
# Check that we don't try to run parallel benchs on 4.14

config_switch_name=$1
build_bench_target=$2

if [[ $build_bench_target =~ multibench* && $config_switch_name =~ 4.14* ]]; then
    echo "Not running parallel tests for $config_switch_name";
    exit 1;
fi
