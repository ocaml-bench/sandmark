[![Build Status](http://cloud.drone.io/api/badges/ocaml-bench/sandmark/status.svg?branch=main)](http://cloud.drone.io/ocaml-bench/sandmark)

# Sandmark

Sandmark is a suite of OCaml benchmarks and a collection of tools to
configure different compiler variants, run and visualise the
results. Sandmark includes both sequential and parallel
benchmarks. The results from the nightly benchmark runs are available
at [sandmark.ocamllabs.io](https://sandmark.ocamllabs.io).

## Quick Start

On Ubuntu 18.04.4 LTS you can try the following commands:

```bash
$ sudo apt-get install curl git libgmp-dev libdw-dev python3-pip jq jo bubblewrap \
	pkg-config m4 unzip
$ pip3 install jupyter seaborn pandas intervaltree

# Install OPAM if not available already
$ sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
$ opam init

$ git clone https://github.com/ocaml-bench/sandmark.git
$ cd sandmark

## For 4.14.0+domains

$ make ocaml-versions/4.14.0+domains.bench

## For 5.1.0+trunk

$ opam pin add -n --yes dune https://github.com/dra27/dune/archive/2.9.3-5.0.0.tar.gz
$ opam install dune

$ TAG='"run_in_ci"' make run_config_filtered.json
$ USE_SYS_DUNE_HACK=1 RUN_CONFIG_JSON=run_config_filtered.json make ocaml-versions/5.1.0+trunk.bench
```

You can now find the results in the `_results/` folder.

## Pre-requisites

On GNU/Linux you need to have `libgmp-dev` installed for several of
the benchmarks to work. You also need to have `libdw-dev` installed
for the profiling functionality of orun to work on Linux.

You can run `make depend` that will check for any missing
dependencies.

## Overview

Sandmark uses opam, with a static local repository, to build external
libraries and applications. It then builds any sandmark OCaml
benchmarks and any data dependencies. Following this it runs the
benchmarks as defined in the `run_config.json`

These stages are implemented in:

 - Opam setup: the `Makefile` handles the creation of an opam switch
   that builds a custom compiler as specified in the
   `ocaml-versions/<version>.var` file.  It then installs all the
   required packages; these packages are statically defined by their
   opam files in the `dependencies` directory.

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

The orun wrapper is packaged in `orun/`, it collects runtime and OCaml
garbage collector statistics producing output in a JSON format. You
can use orun independently of the sandmark benchmarking suite, by
installing it as an opam pin (e.g. `opam install .` from within
`orun/`).

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

* `macro_bench` - A macro benchmark.
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

We can obtain throughput and latency results for the benchmarks. For obtaining
latency results, we can adjust the environment variable `RUN_BENCH_TARGET`.
The scripts for latencies are present in the `pausetimes/` directory. The
`pausetimes_trunk` Bash script obtains the latencies for stock OCaml and the
`pausetimes_multicore` Bash script for Multicore OCaml.

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

## UI

JupyterHub is a multi-user server for hosting Jupyter notebooks. The
Littlest JupyterHub (TLJH) installation is capable of hosting 0-100
users.

The following steps can be used for installation on Ubuntu 18.04.4 LTS:

```bash
$ sudo apt install python3 python3-dev git curl
$ curl https://raw.githubusercontent.com/jupyterhub/the-littlest-jupyterhub/master/bootstrap/bootstrap.py | \
  sudo -E python3 - --admin adminuser
```

If you would like to run the the service on a specific port, say
"8082", you need to update the same in /opt/tljh/state/traefix.toml
file.

You can verify that the services are running from:

```bash
$ sudo systemctl status traefik
$ sudo systemctl status jupyterhub
```

By default, the hub login opens at hostname:15001/hub/login, which is
used by the admin user to create user accounts. The users will be able
to login using hostname:8082/user/username/tree.

You can also setup HTTPS using Let's Encrypt with JuptyerHub using the
following steps:

```bash
$ sudo tljh-config set https.enabled true
$ sudo tljh-config set https.letsencrypt.email e-mail
$ sudo tljh-config add-item https.letsencrypt.domains example.domain
$ sudo tljh-config show
$ sudo tljh-config reload proxy
```

Reference: https://tljh.jupyter.org/en/latest/install/custom-server.html

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
| PIP_DEPENDENCIES | List of Python dependencies | ```intervaltree``` | building compiler and its dependencies |
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
