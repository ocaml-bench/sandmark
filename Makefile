#
# Configuration
#

# Use bash
SHELL=/bin/bash

# Make variable
MAKE=/usr/bin/make

# Set bench command from Dockerfile
BENCH_COMMAND=$(BENCHCMD)

# options for running the benchmarks
# benchmark build target type:
#  - buildbench: build all single threaded tests
BUILD_BENCH_TARGET ?= buildbench

# The run configuration json file that describes the benchmarks and
# configurations.
RUN_CONFIG_JSON ?= run_config.json

# Default dune version to be used
SANDMARK_DUNE_VERSION ?= 3.5.0

# Default URL
SANDMARK_URL ?= ""

# Default packages to remove
SANDMARK_REMOVE_PACKAGES ?= ""

# Default list of packages to override
SANDMARK_OVERRIDE_PACKAGES ?= ""

# Override orun with custom name
SANDMARK_CUSTOM_NAME ?= ""

# Flag to select whether to use sys_dune_hack
USE_SYS_DUNE_HACK ?= false

# benchmark run target type:
#  run_<wrapper> where wrapper is one of the wrappers defined in
#  RUN_CONFIG_JSON. The default RUN_CONFIG_JSON defines two wrappers: perfstat
#  and orun
RUN_BENCH_TARGET ?= run_orun

# Dry run test without executing benchmarks
BUILD_ONLY ?= false

# number of benchmark iterations to run
ITER ?= 1

# setup default for pre benchmark wrappers
# for example PRE_BENCH_EXEC='taskset --cpu-list 3 setarch `uname -m` --addr-no-randomize'
PRE_BENCH_EXEC ?= ""

# option to allow benchmarks to continue even if the opam package install errored
CONTINUE_ON_OPAM_INSTALL_ERROR ?= true

# option to wait for loadavg to settle down once the dependencies are installed and
# before the benchmarks are executed
OPT_WAIT ?= true

IRMIN_DATA_DIR=/tmp/irmin-data

WRAPPER = $(patsubst run_%,%,$(RUN_BENCH_TARGET))

PACKAGES = sexplib0 re yojson react uuidm cpdf nbcodec minilight cubicle orun rungen ctypes

ifeq ($(findstring multibench,$(BUILD_BENCH_TARGET)),multibench)
	PACKAGES += lockfree domainslib
else
	PACKAGES += js_of_ocaml-compiler
endif

DEPENDENCIES = libgmp-dev libdw-dev jq jo python3-pip pkg-config m4 autoconf # Ubuntu
PIP_DEPENDENCIES = intervaltree

.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

.PHONY: bash list depend clean .FORCE
.FORCE:

setup_sys_dune/%: _opam/%
	@ scripts/setup_sys_dune.sh $* $(SANDMARK_DUNE_VERSION) $(USE_SYS_DUNE_HACK)

_opam/opam-init/init.sh:
	@ opam init --bare --no-setup --no-opamrc --disable-sandboxing ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.json
	@ scripts/setup_opam.sh $* ${SANDMARK_URL}

override_packages/%: setup_sys_dune/%
	@ scripts/override_packages.sh $* $(OPAMROOT) "$(PACKAGES)" $(USE_SYS_DUNE_HACK) $(SANDMARK_DUNE_VERSION) $(CONTINUE_ON_OPAM_INSTALL_ERROR) "$(SANDMARK_OVERRIDE_PACKAGES)" "$(SANDMARK_REMOVE_PACKAGES)"

# the file sandmark_git_hash.txt contains the current git hash for this version of sandmark
log_sandmark_hash:
	-git log -n 1


ocaml-versions/%.bench: depend/% check-parallel/% filter/% override_packages/% log_sandmark_hash ocaml-versions/%.json .FORCE
	@ scripts/build.sh $* $(RUN_CONFIG_JSON) $(ITER) $(BUILD_BENCH_TARGET)
	@ scripts/run.sh $* $(BUILD_ONLY) $(WRAPPER) $(RUN_CONFIG_JSON) $(PRE_BENCH_EXEC) $(ITER) $(RUN_BENCH_TARGET) $(SANDMARK_CUSTOM_NAME)

data.json:
	@ scripts/bench_to_json.sh

prep_bench:
	@{	$(BENCH_COMMAND); \
		$(MAKE) data.json; \
	};

bench: prep_bench
	@cat data.json

load_irmin_data:
	mkdir -p /tmp/irmin_trace_replay_artefacts;
	if [ ! -f $(IRMIN_DATA_DIR)/data4_100066commits.repr ]; then \
		wget http://data.tarides.com/irmin/data4_100066commits.repr -P $(IRMIN_DATA_DIR); \
	fi;

filter/%:
	@ scripts/filter.sh $* $(RUN_CONFIG_JSON)

depend/%:
	@ scripts/check_json_url.sh $*
	@ scripts/loadavg.sh $(OPT_WAIT)
	@ scripts/depend.sh "$(DEPENDENCIES)" "$(PIP_DEPENDENCIES)"

check-parallel/%:
	@ scripts/check_parallel.sh $* $(BUILD_BENCH_TARGET)

benchclean:
	rm -rf _build/
	rm -rf _results/

clean:
	rm -rf dependencies/packages/ocaml/*
	rm -rf dependencies/packages/ocaml-base-compiler/*
	rm -rf ocaml-versions/.packages.*
	rm -rf ocaml-versions/*.bench
	rm -rf _build
	rm -rf _opam
	rm -rf _results
	rm -rf *filtered.json
	rm -rf *~
	rm -rf benchmarks/dune
	git clean -fd dependencies/packages/ocaml-base-compiler dependencies/packages/ocaml

list_tags:
	@ echo "List of Tags"
	@ jq '[.benchmarks[].tags] | add | flatten | .[]' *.json | sort -u

bash:
	@ bash
	@ echo "[opam subshell completed]"

%_filtered.json: %.json
	@ jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select(.tags | index($(TAG)) != null)]}' < $< > $@

set-bench-cpu/%:
	@ sed -i "s/cpu-list 5/cpu-list ${BENCH_CPU}/g" $*

%_2domains.json: %.json
	@ jq '{wrappers : .wrappers, benchmarks : [.benchmarks | .[] | {executable : .executable, name: .name, tags: .tags, runs : [.runs | .[] as $$item | if ($$item | .params | split(" ") | .[0] ) == "2" then $$item | .paramwrapper |= "" else empty end ] } ] }' < $< > $@
