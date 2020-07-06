# Sandmark

A benchmarking suite for OCaml.

## Quick Start

On Ubuntu 18.04.4 LTS you can try the following commands:

```bash
$ sudo apt-get install curl git libgmp-dev libdw-dev python3-pip jq bubblewrap m4 unzip
$ pip3 install jupyter seaborn pandas intervaltree

# Install OPAM if not available already
$ sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
$ opam init

$ opam install dune.1.11.4

$ git clone https://github.com/ocaml-bench/sandmark.git
$ cd sandmark
$ make ocaml-versions/4.10.0+stock.bench
$ make ocaml-versions/4.10.0+multicore.bench
```

You can now find the results in the `_results/` folder.

## Pre-requisites

It is necessary that the system dune version is `< 2.0`. The
development uses `ocaml-base-compiler.4.09.0` with `dune.1.11.4` and
`jbuilder.transition`.

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
   `ocaml-versions/<version>.comp` file.  It then installs all the
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

The run_all_parallel.sh script uses chrt and the user executing the
script requires sudo with nopasswd permission, which is quite useful
with periodic nightly builds. Using the `sudo visudo` command on
Ubuntu, for example, you can add the following entry to the
`/etc/sudoers` file to allow a user running the script to execute any
command:

```
username   ALL=(ALL:ALL) NOPASSWD: ALL
```

### Running benchmarks

We can obtain throughput and latency results for the benchmarks.

A config file can be specified with the environment variable `RUN_CONFIG_JSON`,
and the default value is `run_config.json`. This file lists the executable to
run and the wrapper which will be used to collect data (e.g. orun or perf). You
can edit this file to change benchmark parameters or wrappers.

The build bench target determines the type of benchmark being built. It can be
specified with the environment variable `BUILD_BENCH_TARGET`, and the default
value is `buildbench` which runs the serial benchmarks. For executing the
parallel benchmarks use `multibench_parallel`. You can also setup a custom
bench and add only the benchmarks you care about.

For obtaining latency results, we can adjust the environment variable
`RUN_BENCH_TARGET`. The scripts for latencies are present in the `pausetimes/`
directory. The `pausetimes_trunk` Bash script obtains the latencies for stock
OCaml and the `pausetimes_multicore` Bash script for Multicore OCaml.

### Results

After a run is complete, the results will be available in the `_results`
directory.

Jupyter notebooks are available in the `notebooks` directory to parse and
visualise the results, for both serial and parallel benchmarks. To run the
Jupyter notebooks for your results, copy your results to `notebooks/
sequential` folder for sequential benchmarks and `notebooks/parallel` folder
for parallel benchmarks. It is sufficient to copy only the consolidated
bench files, which are present as
`_results/<comp-version>/<comp-version>.orun.bench`. You can run the notebooks
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
    folder in `benchmarks/` has its own dune file, add a dune entry for your
    benchmark in it. Also add you code and input files if any to an alias,
    `buildbench` for sequential benchmarks and `multibench_parallel` for
    parallel benchmarks.

 - **Add commands to run your applications:**
    Add an entry for your benchmark run to the appropriate config file;
    `run_config.json` for sequential benchmarks and
    `multicore_parallel_run_config.json` for parallel benchmarks.

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

## User configurable benchmark wrapper

To run a macro benchmark with a custom range of processors/isolated CPUs/ a conditional string can be passed with `PARAMWRAPPER`.

For example :
```bash
$ make multicore_parallel_run_config_macro.json PARAMWRAPPER="if params < 16 then paramwrapper = 2-15 else paramwrapper = 2-15,16-21"
```
In the above example strings : `16`, `2-15`, `2-15,16-21` are used to construct a json file containing a `paramwrapper` record with the value : `taskset --cpu-list 2-15 chrt -r 1` or `taskset --cpu-list 2-15,16-21 chrt -r 1`. The `paramwrapper` value switches to one or the other depending on the value `params` is being compared to in this case `16`.

The command above generates a new `.json` file. In this example it is `run_config_macro.json`.

If no optional string is provided it defaults to
```bash
PARAMWRAPPER="if params < 16 then paramwrapper = 2-15 else paramwrapper = 2-15,16-27"
```
