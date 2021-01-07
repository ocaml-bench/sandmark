[![Build Status](http://cloud.drone.io/api/badges/ocaml-bench/sandmark/status.svg?branch=master)](http://cloud.drone.io/ocaml-bench/sandmark)

# Sandmark

A benchmark suite for OCaml.

## Quick Start

On Ubuntu 18.04.4 LTS you can try the following commands:

```bash
$ sudo apt-get install curl git libgmp-dev libdw-dev python3-pip jq bubblewrap \
	pkg-config m4 unzip
$ pip3 install jupyter seaborn pandas intervaltree

# Install OPAM if not available already
$ sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
$ opam init

$ opam install dune.2.6.0

$ git clone https://github.com/ocaml-bench/sandmark.git
$ cd sandmark
$ make depend

$ TAG='"run_in_ci"' make run_config_filtered.json
$ OPAMSOLVERTIMEOUT=0 BUILD_BENCH_TARGET=buildbench RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/4.10.0+multicore.bench
```

You can now find the results in the `_build/analytics` folder.

## Pre-requisites

On GNU/Linux you need to have `libgmp-dev` installed for several of
the benchmarks to work. You also need to have `libdw-dev` installed
for the profiling functionality of orun to work on Linux.

You can run `make depend` that will check for any missing
dependencies.

## Overview

Sandmark uses opam to build external libraries and applications. It
then builds any sandmark OCaml benchmarks and any data
dependencies. Following this it runs the benchmarks as defined in the
`run_config.json`

These stages are implemented in:

 - Opam setup: the `Makefile` handles the creation of an opam switch
   that builds a custom compiler as specified in the
   `ocaml-versions/<version>.json` file.  It then installs all the
   required packages and their `dependencies`.

 - Runplan: the list of benchmarks which will run along with the
   measurement wrapper (e.g. orun or perf) is specified in
   `run_config.json`. This config file is used to generate dune files
   which will run the benchmarks.

 - Build: dune is used to build all the sandmark OCaml benchmarks that
   are in the `benchmarks` directory.

 - Execute: dune is used to execute all the benchmarks specified in
   the runplan using the benchmark wrapper defined in
   `run_config.json` and specified via the `RUN_BENCH_TARGET` variable
   passed to the makefile.

## Configuration

The compiler switch and its configuration options can be specified in
a .json file in the ocaml-versions/ directory. It uses the JSON syntax
as shown in the following example:

```
{
  "name" : "ocaml-multicore/ocaml-multicore:parallel_minor_gc",
  "configure" : "-q",
  "runparams" : "v=0x400"
}
```

The various options are described below:

- `name` is MANDATORY and specifies the ocaml compiler switch to be
  installed.

- `configure` is OPTIONAL, and you can use this setting to pass
  specific flags to the `configure` script.

- `runparams` is OPTIONAL, and its values are passed to OCAMLRUNPARAM
  when building the compiler.

## Execution

### orun

The orun wrapper collects runtime and OCaml garbage collector
statistics producing output in a JSON format. You can use orun
independently of the sandmark benchmarking suite after installion from
opam.ocaml.org.

### Using a directory different than /home

Special care is needed if you happen to run sandmark from a directory
different than home.

If you get error like `# bwrap: execvp dune: No such file or
directory`, it may be because opam's sandboxing prevent executables to
be run from non-standard locations.

In order to get around this issue, you may specify
`OPAM_USER_PATH_RO=/directory/to/sandmark` in order to whitelist this
location from sandboxing.

## Benchmarks

Ensure that the respective .json configuration files have the
appropriate settings.

If using `RUN_BENCH_TARGET=run_orunchrt` then the benchmarks will
run using `chrt -r 1`. You may need to give the user permissions
to execute `chrt`, one way to do this can be:
```
sudo setcap cap_sys_nice=ep /usr/bin/chrt
```

### Configuring the benchmark runs

A config file can be specified with the environment variable `RUN_CONFIG_JSON`,
and the default value is `run_config.json`. This file lists the executable to
run and the wrapper which will be used to collect data (e.g. orun or perf). You
can edit this file to change benchmark parameters or wrappers.

The benchmarks also have associated tags which classify the benchmarks. The
current tags are:

* `macro_bench` - A macro benchmark.
* `run_in_ci` - This benchmark is run in the CI.
* `lt_1s` - running time is less than 1s on the `turing` machine.
* `1s_10s` - running time is between 1s and 10s on the `turning` machine.
* `10s_100s` - running time is between 10s and 100s on the `turing` machine.
* `gt_100s` - running time is greater than 100s on the `turing` machine.

The benchmarking machine `turing` is an Intel Xeon Gold 5120 CPU with 64GB of
RAM housed at IITM.

The `run_config.json` file may be filtered based on the tag. For example,

```bash
$ TAG='"macro_bench"' make run_config_filtered.json
```

filters the `run_config.json` file to only contain the benchmarks tagged as
`macro_bench`.

### Running benchmarks

The build bench target determines the type of benchmark being built. It can be
specified with the environment variable `BUILD_BENCH_TARGET`, and the default
value is `buildbench` which runs the serial benchmarks. For executing the
parallel benchmarks use `multibench_parallel`. You can also setup a custom
bench and add only the benchmarks that you care about.

We can obtain throughput and latency results for the benchmarks. For obtaining
latency results, we can adjust the environment variable `RUN_BENCH_TARGET`.

### Results

After a run is complete, the results will be available in the `_build/analytics`
directory.

### Adding benchmarks

You can add new benchmarks as follows:

 - **Add dependencies to packages:**
    If there are any package dependencies your benchmark has that are not
    already included in Sandmark, add its opam file to
    `dependencies/packages/<package-name>/<package-version>/opam`. If the
    package depends on other packages, repeat this step for all of those
    packages. Add the package to `PACKAGES` variable in the Makefile.

 - **Add benchmark files:**
    Find a relevant folder in `benchmarks/` and add your code to it. Feel free
    to create a new folder if you don't find any existing ones relevant. Every
    folder in `benchmarks/` has its own dune file; if you are creating a new
    directory for your benchmark, also create a dune file in that directory and
    add a stanza for your benchmark. If you are adding your benchmark to an
    existing directory, add a dune stanza for your benchmark in the directory's
    dune file.

    Also add you code and input files if any to an alias,
    `buildbench` for sequential benchmarks and `multibench_parallel` for
    parallel benchmarks. For instance, if you are adding a parallel benchmark
    `benchmark.ml` and its input file `input.txt` to a directory, in that
    directory's dune file add
    ```
    (alias (name multibench_parallel) (deps benchmark.ml input.txt))
    ```

 - **Add commands to run your applications:**
    Add an entry for your benchmark run to the appropriate config file;
    `run_config.json` for sequential benchmarks and
    `multicore_parallel_run_config.json` for parallel benchmarks.

## Multicore Notes

### ctypes

ctypes 14.0.0 doesn't support multicore yet. A workaround is to update
`dependencies/packages/ctypes/ctypes.0.14.0/opam` to use
`https://github.com/yallop/ocaml-ctypes/archive/14d0e913e82f8de2ecf739970561066b2dce70b7.tar.gz`
as the source url.

### OS X

*This is only needed for multicore versions before this
[commit](https://github.com/ocaml-multicore/ocaml-multicore/commit/cb094cbc53c30a801a97f1cb1fb0b0d276d54aaf)*

The ocaml-update-c command in multicore needs to run with GNU
sed. `sed` will default to a BSD sed on OS X. One way to make things
work on OS X is to install GNU sed with homebrew and then update the
`PATH` you run sandmark with to pick up the GNU version.
