#!/bin/bash
# Script called after we run the benchmarks.
# Find a file in _results/ and output it in data.json

output=data.json;
files=$(find _results/*.bench 2>/dev/null)
nb_files=$(echo "$files" | wc -l)

if [ "$nb_files" != "1" ]; then
    echo "Found $nb_files!=1 files matching _results/*.bench, can't produce $output";
    exit 1;
fi

is_first_line=true;
while read -r line; do
    if $is_first_line; then
        echo "$line" | jq '. | {config: ., results: []}' > "$output";
        is_first_line=false;
    else
        bench=$(echo "$line" | jq '. | {name: .name, command: .command, context: {"ocaml.version": .ocaml.version, "ocaml.c_compiler": .ocaml.c_compiler, "ocaml.architecture": .ocaml.architecture, "ocaml.word_size": .ocaml.word_size, "ocaml.system": .ocaml.system, "ocaml.stats": .ocaml.stats, "ocaml.function_sections": .ocaml.function_sections, "ocaml.supports_shared_libraries": .ocaml.supports_shared_libraries, ocaml_url: .ocaml_url}, metrics: {time_secs: .time_secs, maxrss_kB: .maxrss_kB, user_time_secs: .user_time_secs, sys_time_secs: .sys_time_secs, "gc.allocated_words": .gc.allocated_words, "gc.minor_words": .gc.minor_words, "gc.promoted_words": .gc.promoted_words, "gc.major_words": .gc.major_words, "gc.minor_collections": .gc.minor_collections, "gc.major_collections": .gc.major_collections, "gc.heap_words": .gc.heap_words, "gc.top_heap_words": .gc.top_heap_words, "gc.mean_space_overhead": .gc.mean_space_overhead, codesize: .codesize}}');
        string=".results += [$bench]";
        jq "$string" "$output" > "$output.tmp" && mv "$output.tmp" "$output";
    fi;
done < "$files"
