#!/bin/bash
# Script called before we run the benchmarks.
# Filter the contents of run_config_json.

config_switch_name=$1
run_config_json=$2

recognized=$(echo "$config_switch_name" | grep -E '.*(4\.14|5\.0\.1|5\.1\.0|5\.2\.0).*' -)

if [ -n "$recognized" ]; then
    # Recognized compiler variant (4.14, 5.0.1, 5.1.0, 5.2.0)
    echo "Filtering some benchmarks for OCaml $config_switch_name";
    jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select( .name as $name | ["irmin_replay", "cpdf", "frama-c", "js_of_ocaml", "graph500_kernel1", "graph500_kernel1_multicore"] | index($name) | not )]}' "$run_config_json" >"$run_config_json".tmp;
    mv "$run_config_json".tmp "$run_config_json";
    echo "(data_only_dirs irmin cpdf frama-c)" >benchmarks/dune
else
    echo "Not filtering benchmarks for OCaml $config_switch_name"
fi
