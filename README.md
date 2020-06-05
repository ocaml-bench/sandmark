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

$ make ocaml-versions/4.06.0.bench
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

### Configuration

The benchmarks which are executed are specified in
`run_config.json`. This file specifies the executable to run and the
wrapper which will be used to collect data (e.g. orun or perf). You
can edit this file to change benchmark parameters or setup a custom
set of benchmarks that you care about.

### Adding benchmarks

You can add benchmarks as follows:

 - Add any opam packages you need, by adding the opam files to
   `repository/` and the package install to `PACKAGES` in the
   `Makefile`

 - Add any OCaml code to the `benchmarks/` directory, it is assumed
   dune will build it.

 - Add your benchmark command line to `run_config.json`

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
