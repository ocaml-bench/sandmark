[![Build Status](https://github.com/ocaml-bench/sandmark/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/ocaml-bench/sandmark/actions/workflows/main.yml/badge.svg?branch=main)

# Sandmark

Sandmark is a suite of OCaml benchmarks and a collection of tools to configure
different compiler variants, run and visualise the results.

Sandmark includes both sequential and parallel benchmarks. The results from the
nightly benchmark runs are available at
[sandmark.tarides.com](https://sandmark.tarides.com).

## 📣 Attention Users 🫵

If you are interested in only running the sandmark benchmarks on your compiler
branch, please add your branch to [sandmark nightly
config](https://github.com/ocaml-bench/sandmark-nightly-config#adding-your-compiler-branch-to-the-nightly-runs). Read
on if you are interested in setting up your own instance of Sandmark for local
runs.

# FAQ

## How do I run the benchmarks locally?

On Ubuntu 20.04.4 LTS or newer, you can run the following commands:

```bash
# Clone the repository
$ git clone https://github.com/ocaml-bench/sandmark.git && cd sandmark

# Install dependencies
$ make install-depends

# Install OPAM if not available already
$ sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
$ opam init

## You can run all the serial or parallel benchmarks using the respective run_all_*.sh scripts
## You can edit the scripts to change the ocaml-version for which to run the benchmarks

$ bash run_all_serial.sh   # Run all serial benchmarks
$ bash run_all_parallel.sh   # Run all parallel benchmarks
```

You can now find the results in the `_results/` folder.

## How do I add new benchmarks?

See [CONTRIBUTING.md](./CONTRIBUTING.md)

## How do I visualize the benchmark results?

### Local runs

1. To visualize the local results, there are a handful of IPython notebooks
   available in [notebooks/](./notebooks/), which are maintained on a
   best-effort basis.  See the [README](./notebooks/README.md) for more
   information on how to use them.

2. You can run
   [sandmark-nightly](https://github.com/ocaml-bench/sandmark-nightly?tab=readme-ov-file#how-to-run-the-webapp-locally)
   locally and visualize the local results directory using the local Sandmark
   nighly app.

### Nightly production runs

Sandmark benchmarks are configured to run nightly on [navajo](./nightly_navajo.sh) and
[turing](./nightly_turing.sh). The results for these benchmark runs are available at
[sandmark.tarides.com](https://sandmark.tarides.com).

## How are the machines tuned for the benchmarking?

You can find detailed notes on the OS settings for the benchmarking servers
[here](https://github.com/ocaml-bench/ocaml_bench_scripts/?tab=readme-ov-file#notes-on-hardware-and-os-settings-for-linux-benchmarking)

# Overview

Sandmark uses opam, with a static local repository, to build external
libraries and applications. It then builds any sandmark OCaml
benchmarks and any data dependencies. Following this it runs the
benchmarks as defined in the `run_config.json`

These stages are implemented in:

 - Opam setup: the `Makefile` handles the creation of an opam switch that
   builds a custom compiler as specified in the `ocaml-versions/<version>.json`
   file.  It then installs all the required packages; the packages versions are
   defined in `dependencies/template/*.opam` files. The dependencies can be
   patched or tweaked using `dependencies` directory.

 - Runplan: the list of benchmarks which will run along with the
   measurement wrapper (e.g. orun or perf) is specified in
   `run_config.json`. This config file is used to generate dune files
   which will run the benchmarks.

 - Build: dune is used to build all the sandmark OCaml benchmarks that
   are in the `benchmarks` directory.

 - Execute: dune is used to execute all the benchmarks sepcified in
   the runplan using the benchmark wrapper defined in
   `run_config.json` and specified via the `RUN_BENCH_TARGET` variable
   passed to the makefile.


## Configuration of the compiler build

The compiler variant and its configuration options can be specified in
a .json file in the ocaml-versions/ directory. It uses the JSON syntax
as shown in the following example:

```json
{
  "url" : "https://github.com/ocaml-multicore/ocaml-multicore/archive/parallel_minor_gc.tar.gz",
  "configure" : "-q",
  "runparams" : "v=0x400"
}
```

The various options are described below:

- `url` is MANDATORY and provides the web URL to download the source
  for the ocaml-base-compiler.

- `configure` is OPTIONAL, and you can use this setting to pass
  specific flags to the `configure` script.

- `runparams` is OPTIONAL, and its values are passed to OCAMLRUNPARAM
  when building the compiler. _Note that this variable is not used for
  the running of benchmarks, just the build of the compiler_

## Execution

### orun

The orun wrapper is packaged as a separate package
[here](https://opam.ocaml.org/packages/orun/).  It collects runtime and OCaml
garbage collector statistics producing output in a JSON format.

You can use orun independently of the sandmark benchmarking suite, by
installing it, e.g. using `opam install orun`.

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

You can execute both serial and parallel benchmarks using the
`run_all_serial.sh` and `run_all_parallel.sh` scripts.
Ensure that the respective .json configuration files have the
appropriate settings.

If using `RUN_BENCH_TARGET=run_orunchrt` then the benchmarks will
run using `chrt -r 1`.

**IMPORTANT:** `chrt -r 1` is **necessary** when using
`taskset` to run parallel programs. Otherwise, all the domains will be
scheduled on the same core and you will see slowdown with increasing
number of domains.

You may need to give the user permissions to execute `chrt`, one way
to do this can be:
```
sudo setcap cap_sys_nice=ep /usr/bin/chrt
```

### Configuring the benchmark runs

A config file can be specified with the environment variable `RUN_CONFIG_JSON`,
and the default value is `run_config.json`. This file lists the executable to
run and the wrapper which will be used to collect data (e.g. orun or perf). You
can edit this file to change benchmark parameters or wrappers.

The `environment` within which a wrapper runs allows the user to configure
variables such as `OCAMLRUNPARAM` or `LD_PRELOAD`. For example this wrapper
configuration:
```json
{
  "name": "orun-2M",
  "environment": "OCAMLRUNPARAM='s=2M'",
  "command": "orun -o %{output} -- taskset --cpu-list 5 %{command}"
}
```
would allow
```sh
$ RUN_BENCH_TARGET=run_orun-2M make ocaml-versions/5.0.0+trunk.bench
```
to run the benchmarks on 5.0.0+trunk with a 2M minor heap setting taskset
onto CPU 5.

#### Tags

The benchmarks also have associated tags which classify the benchmarks. The
current tags are:

* `macro_bench` - A macro benchmark. Benchmarks with this tag are automatically
    run nightly.
* `run_in_ci` - This benchmark is run in the CI.
* `lt_1s` - running time is less than 1s on the `turing` machine.
* `1s_10s` - running time is between 1s and 10s on the `turing` machine.
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
bench and add only the benchmarks you care about.

Sandmark has support to build and execute the serial benchmarks in
byte mode. A separate `run_config_byte.json` file has been created for
the same. These benchmarks are relatively slower compared to their
native execution. You can use the following commands to run the serial
benchmarks in byte mode:

```bash
$ opam install dune.2.9.0
$ USE_SYS_DUNE_HACK=1 SANDMARK_CUSTOM_NAME=5.0.0 BUILD_BENCH_TARGET=bytebench \
    RUN_CONFIG_JSON=run_config_byte.json make ocaml-versions/5.0.0+stable.bench
```

We can obtain throughput and latency results for the benchmarks. To obtain
latency results, we can set the environment variable `RUN_BENCH_TARGET` to
`run_pausetimes`, which will run the benchmarks with
[olly](https://github.com/sadiqj/runtime_events_tools) and collect the GC tail
latency profile of the runs (see the script `pausetimes/pausetimes`).
The results will be files in the `_results` directory with a `.pausetimes.*.bench` suffix.

The perf stat output results can be obtained by setting the
environment variable `RUN_BENCH_TARGET` to `run_perfstat`. In order to
use the `perf` command, the `kernel.perf_event_paranoid` parameter
should be set to -1 using the sysctl command. For example:

```bash
$ sudo sysctl -w kernel.perf_event_paranoid=-1
```

You can also set it permanently in the /etc/sysctl.conf file.

### Results

After a run is complete, the results will be available in the `_results`
directory.

Jupyter notebooks are available in the `notebooks` directory to parse and
visualise the results, for both serial and parallel benchmarks. To run the
Jupyter notebooks for your results, copy your results to `notebooks/
sequential` folder for sequential benchmarks and `notebooks/parallel` folder
for parallel benchmarks. It is sufficient to copy only the consolidated
bench files, which are present as
`_results/<comp-version>/<comp-version>.bench`. You can run the notebooks
with

```
$ jupyter notebook
```

### Logs

The logs for nightly runs are available at
[here](https://github.com/ocaml-bench/sandmark-nightly/commits/testing). Runs
which are considered successful are copied to the [main branch of the
repo](https://github.com/ocaml-bench/sandmark-nightly/commits/main), so that
they can be visualized using the [sandmark nightly
UI](https://sandmark.tarides.com/)

### Config files

The `*_config.json` files used to build benchmarks

 - **run_config.json** : Runs sequential benchmarks with stock OCaml variants in CI and sandmark-nightly on the IITM machine(turing)
 - **multicore_parallel_run_config.json** : Runs parallel benchmarks with multicore OCaml in CI and sandmark-nightly on the IITM machine(turing)
 - **multicore_parallel_navajo_run_config.json** : Runs parallel benchmarks with multicore OCaml in sandmark-nightly on Navajo (AMD EPYC 7551 32-Core Processor) machine
 - **micro_multicore.json** : To locally run multicore specific micro benchmarks

### Benchmarks status

The following table marks the benchmarks that are currently not working with any one of the variants that are used in the CI. These benchmarks are known to fail and have an issue tracking their progress.

| Variants | Benchmarks | Issue Tracker |
|---|---|---|
| 5.0.0+trunk.bench | irmin benchmarks | [sandmark#262](https://github.com/ocaml-bench/sandmark/issues/262) |
| 4.14.0+domains.bench | irmin benchmarks | [sandmark#262](https://github.com/ocaml-bench/sandmark/issues/262) |

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

## Makefile Variables

| Name | Description | Default Values | Usage |
| ---- | ----------- | -------------- | ----------------- |
| BENCH_COMMAND | TAG selection and make command to run benchmarks | 4.14.0+domains for CI | With current-bench |
| BUILD_BENCH_TARGET | Target selection for sequential (buildbench) and parallel (multibench) benchmarks | `buildbench` | building benchmark |
| BUILD_ONLY | If the value is equal to 0 then execute the benchmarks otherwise skip the benchmark execution and exit the sandmark build process | 0 | building benchmark |
| CONTINUE_ON_OPAM_INSTALL_ERROR | Allow benchmarks to continue even if the opam package install errors out | true | executing benchmark |
| DEPENDENCIES | List of Ubuntu dependencies | ```libgmp-dev libdw-dev jq python3-pip pkg-config m4``` | building compiler and its dependencies |
| ENVIRONMENT | Function that gets the `environment` parameter from wrappers in `*_config.json` | null string | building compiler and its dependencies |
| ITER | Indicates the number of iterations the sandmark benchmarks would be executed | 1 | executing benchmark |
| OCAML_CONFIG_OPTION | Function that gets the runtime parameters `configure` in `ocaml-versions/*.json` | null string | building compiler and its dependencies |
| OCAML_RUN_PARAM | Function that gets the runtime parameters `run_param` in `ocaml-versions/*.json` | null string | building compiler and its dependencies |
| PACKAGES | List of all the benchmark dependencies in sandmark | ```cpdf conf-pkg-config conf-zlib bigstringaf decompress camlzip menhirLib menhir minilight base stdio dune-private-libs dune-configurator camlimages yojson lwt zarith integers uuidm react ocplib-endian nbcodec checkseum sexplib0 eventlog-tools irmin cubicle conf-findutils index logs mtime ppx_deriving ppx_deriving_yojson ppx_irmin repr ppx_repr irmin-layers irmin-pack ``` | building benchmark |
| PRE_BENCH_EXEC | Any specific commands that needed to be executed before the benchmark. For eg. `PRE_BENCH_EXEC='taskset --cpu-list 3 setarch uname -m --addr-no-randomize'` | null string | executing benchmark | RUN_BENCH_TARGET | The executable to be used to run the benchmarks | `run_orun` | executing benchmark |
| RUN_BENCH_TARGET | The executable to be used to run the benchmarks | `run_orun` | executing benchmark |
| RUN_CONFIG_JSON | Input file selection that contains the list of benchmarks | `run_config.json` | executing benchmark |
| SANDMARK_DUNE_VERSION | Default dune version to be used | 2.9.0 | building compiler and its dependencies |
| SANDMARK_OVERRIDE_PACKAGES | A list of dependency packages with versions that can be overrided (optional) | "" | building compiler and its dependencies |
| SANDMARK_REMOVE_PACKAGES | A list of dependency packages to be dynamically removed (optional) | "" | building compiler and its dependencies |
| SANDMARK_URL | OCaml compiler source code URL used to build the benchmarks | "" | building compiler and its dependencies |
| SYS_DUNE_BASE_DIR | Function that returns the path of the system installed dune for use with benchmarking | dune package present in the local opam switch | building compiler and its dependencies |
| USE_SYS_DUNE_HACK | If the value is 1 then use system installed dune | 0 | building compiler and its dependencies |
| WRAPPER | Function to get the wrapper out of `run_<wrapper-name>` | run_orun | executing benchmark |
