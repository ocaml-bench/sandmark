# sandmark

a benchmarking suite for ocaml

try `make ocaml-versions/4.06.0.bench`

## running a given benchmark

`make ocaml-versions/4.06.0.bench BENCH_TARGET=benchmarks/js_of_ocaml/bench`

## pre-requisites

on Linux you need to have `libgmp-dev` installed for several of the benchmarks to work. 

## running from a directory different than /home

special care is needed if you happen to run sandmark from a directory different than home.

if you get error like `# bwrap: execvp dune: No such file or directory`, it may be because opam's sandboxing prevent executables to be run from non-standard locations.

to get around this issue, you may specify `OPAM_USER_PATH_RO=/directory/to/sandmark` in order to whitelist this location from sandboxing.

## Multicore notes

### running multicore specific benchmarks

`make ocaml-versions/4.06.1+multicore.bench BENCH_TARGET=multibench`

### ctypes

ctypes 14.0.0 doesn't support multicore. A workaround is to update `dependencies/packages/ctypes/ctypes.0.14.0/opam` to use `https://github.com/yallop/ocaml-ctypes/archive/14d0e913e82f8de2ecf739970561066b2dce70b7.tar.gz` as the source url. 

### OS X

*This is only needed for multicore versions before this [commit](https://github.com/ocaml-multicore/ocaml-multicore/commit/cb094cbc53c30a801a97f1cb1fb0b0d276d54aaf)*

The ocaml-update-c command in multicore needs to run with GNU sed. `sed` will default to a BSD sed on OS X. One way to make things work on OS X is to install GNU sed with homebrew and then update the `PATH` you run sandmark with to pick up the GNU version. 

