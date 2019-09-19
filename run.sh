#! /bin/sh

# Helper script to run a given benchmark target through the
# performance tool for given number of iterations using the OCaml
# version provided.

progname=${0##*/}
usage()
{
    echo "Usage: ${progname} iterations ocaml_prefix bench_target perf_tool outfn"
    exit 1
}

if [ $# != 5 ]; then usage; fi
iterations=$1
ocaml_prefix=$2
bench_target=$3
perf_tool=$4
outfn=$5
bench_path="_build/default/benchmarks"
root=$(pwd)
export OPAMROOT=${root}/_opam

if [ ${bench_target} = "all" ]; then
    echo "TODO: Run all benchmarks...";
else
    bn=$(basename ${bench_target})
    cd ${bench_path}/${bn}
    for i in $(seq 1 ${iterations}); do
	opam exec --switch ${ocaml_prefix} -- \
	     ${perf_tool} -o ${bn}.${i}.bench -- ./${bn}.exe;
    done
    cd ${root}
    find _build/ -name '*.bench' | xargs cat > ${outfn}
fi
