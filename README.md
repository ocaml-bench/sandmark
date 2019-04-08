# sandmark

a benchmarking suite for ocaml

try `make ocaml-versions/4.06.0.bench`


## running a given benchmark

`make ocaml-versions/4.06.0.bench BENCH_TARGET=benchmarks/js_of_ocaml/bench`

## pre-requisites

on Linux you need to have `libgmp-dev` installed for several of the benchmarks to work. 

## Multicore and OS X

The ocaml-update-c command in multicore needs to run with GNU sed. `sed` will default to a BSD sed on OS X. One way to make things work on OS X is to install GNU sed with homebrew and then update the `PATH` you run sandmark with to pick up the GNU version. 

