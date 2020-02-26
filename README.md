# sandmark

a benchmarking suite for ocaml

try `make ocaml-versions/4.06.0.bench`

then look for the results in `_results/`

## quikstart multicore
```
    make multicore_parallel_run_config_macro.json
    bash run_all_parallel.sh
```

## pre-requisites

It is necessary that the system dune version is `< 2.0`. The development uses
`ocaml-base-compiler.4.09.0` with `dune.1.11.4` and `jbuilder.transition`.

On Linux you need to have `libgmp-dev` installed for several of the benchmarks
to work. You also need to have `libdw-dev` installed for the profiling
functionality of orun to work on Linux.

## overview

Sandmark uses opam, with a static local repository, to build external libraries
and applications. It then builds any sandmark OCaml benchmarks and any data
dependencies. Following this it runs the benchmarks as defined in the
`run_config.json`

These stages are implemented in:
 - Opam setup: the `Makefile` handles the creation of an opam switch that builds
   a custom compiler as specified in the `ocaml-versions/<version>.comp` file.
   It then installs all the required packages; these packages are statically
   defined by their opam files in the `dependencies` directory.
 - Runplan: the list of benchmarks which will run along with the measurement
   wrapper (e.g. orun or perf) is specified in `run_config.json`. This config
   file is used to generate dune files which will run the benchmarks.
 - Build: dune is used to build all the sandmark OCaml benchmarks that are in
   the `benchmarks` directory.
 - Execute: dune is used to execute all the benchmarks sepcified in the runplan
   using the benchmark wrapper defined in `run_config.json` and specified via
   the `RUN_BENCH_TARGET` variable passed to the makefile.

## running from a directory different than /home

special care is needed if you happen to run sandmark from a directory different
than home.

if you get error like `# bwrap: execvp dune: No such file or directory`, it may
be because opam's sandboxing prevent executables to be run from non-standard
locations.

to get around this issue, you may specify
`OPAM_USER_PATH_RO=/directory/to/sandmark` in order to whitelist this location
from sandboxing.

## orun

The orun wrapper is packaged in `orun/`, it collects runtime and OCaml garbage
collector statistics producing output in a JSON format. You can use orun
independently of the sandmark benchmarking suite, by installing it as an opam
pin (e.g. `opam install .` from within `orun/`).

## configuring benchmarks

The benchmarks which are executed are specified in `run_config.json`. This file
specifies the executable to run and the wrapper which will be used to collect
data (e.g. orun or perf). You can edit this file to change benchmark parameters
or setup a custom set of benchmarks you care about.

## adding benchmarks

You can add benchmarks as follows:
 - add any opam packages you need, by adding the opam files to `repository/` and
   the package install to `PACKAGES` in the `Makefile`
 - add any OCaml code to the `benchmarks/` directory, it is assumed dune will
   build it.
 - add your benchmark command line to `run_config.json`

## Multicore notes

### ctypes

ctypes 14.0.0 doesn't support multicore. A workaround is to update
`dependencies/packages/ctypes/ctypes.0.14.0/opam` to use
`https://github.com/yallop/ocaml-ctypes/archive/14d0e913e82f8de2ecf739970561066b2dce70b7.tar.gz`
as the source url.

### OS X

*This is only needed for multicore versions before this
[commit](https://github.com/ocaml-multicore/ocaml-multicore/commit/cb094cbc53c30a801a97f1cb1fb0b0d276d54aaf)*

The ocaml-update-c command in multicore needs to run with GNU sed. `sed` will
default to a BSD sed on OS X. One way to make things work on OS X is to install
GNU sed with homebrew and then update the `PATH` you run sandmark with to pick
up the GNU version.

