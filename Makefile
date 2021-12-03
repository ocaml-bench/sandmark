#
# Configuration
#

# Use bash
SHELL=/bin/bash

# Make variable
MAKE=/usr/bin/make

# options for running the benchmarks
# benchmark build target type:
#  - buildbench: build all single threaded tests
BUILD_BENCH_TARGET ?= buildbench

# The run configuration json file that describes the benchmarks and
# configurations.
RUN_CONFIG_JSON ?= run_config.json

# Default dune version to be used
DEFAULT_DUNE_VERSION ?= 2.9.0

# Flag to select whether to use sys_dune_hack
USE_SYS_DUNE_HACK ?= 0

# benchmark run target type:
#  run_<wrapper> where wrapper is one of the wrappers defined in
#  RUN_CONFIG_JSON. The default RUN_CONFIG_JSON defines two wrappers: perf and
#  orun
RUN_BENCH_TARGET ?= run_orun

# Dry run test without executing benchmarks
BUILD_ONLY ?= 0

# number of benchmark iterations to run
ITER ?= 1

# setup default for pre benchmark wrappers
# for example PRE_BENCH_EXEC='taskset --cpu-list 3 setarch `uname -m` --addr-no-randomize'
PRE_BENCH_EXEC ?=

# option to allow benchmarks to continue even if the opam package install errored
CONTINUE_ON_OPAM_INSTALL_ERROR ?= true

WRAPPER = $(patsubst run_%,%,$(RUN_BENCH_TARGET))

PACKAGES = sexplib0 re yojson react uuidm cpdf nbcodec minilight cubicle orun rungen eventlog-tools

ifeq ($(findstring multibench,$(BUILD_BENCH_TARGET)),multibench)
	PACKAGES +=  lockfree kcas domainslib ctypes
else
	PACKAGES += ctypes js_of_ocaml-compiler
endif

DEPENDENCIES = libgmp-dev libdw-dev jq jo python3-pip pkg-config m4 autoconf # Ubuntu
PIP_DEPENDENCIES = intervaltree

.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

.PHONY: bash list depend clean

# HACK: we are using the system installed dune to avoid breakages with
# multicore and 4.09/trunk
# This is a workaround for r14/4.09/trunk until better solutions arrive
SYS_DUNE_BASE_DIR ?= $(subst /bin/dune,,$(shell which dune))

setup_sys_dune/%: _opam/%
	$(eval OVERRIDE_DUNE = $(shell sed -n 's/.*dune\.\([0-9]\.[0-9]\.[0-9]\).*/\1/p' ocaml-versions/$*.json))
	$(if $(strip $(OVERRIDE_DUNE)), 				\
		$(eval DEFAULT_DUNE_VERSION = "$(OVERRIDE_DUNE)") 	\
		@echo "Overriding dune with "$(DEFAULT_DUNE_VERSION),	\
		@echo "Using default dune.$(DEFAULT_DUNE_VERSION)")
ifeq (1, $(USE_SYS_DUNE_HACK))
	@echo $(SYS_DUNE_BASE_DIR)
	@echo "Linking to system dune files found at: "$(SYS_DUNE_BASE_DIR)
	@echo $(SYS_DUNE_BASE_DIR)"/bin/dune --version = "$(shell $(SYS_DUNE_BASE_DIR)/bin/dune --version)
	@rm -rf $(CURDIR)/_opam/sys_dune
	@mkdir -p $(CURDIR)/_opam/sys_dune/bin
	@mkdir -p $(CURDIR)/_opam/sys_dune/lib
	ln -s $(SYS_DUNE_BASE_DIR)/bin/dune $(CURDIR)/_opam/sys_dune/bin/dune
	ln -s $(SYS_DUNE_BASE_DIR)/bin/jbuilder $(CURDIR)/_opam/sys_dune/bin/jbuilder
	ln -s $(SYS_DUNE_BASE_DIR)/lib/dune $(CURDIR)/_opam/sys_dune/lib/dune
endif

ocamls=$(wildcard ocaml-versions/*.json)

_opam/opam-init/init.sh:
	opam init --bare --no-setup --no-opamrc --disable-sandboxing ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.json
	rm -rf dependencies/packages/ocaml/ocaml.$*
	rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	mkdir -p dependencies/packages/ocaml/ocaml.$*
	cp -R dependencies/template/ocaml/* dependencies/packages/ocaml/ocaml.$*/
	mkdir -p dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	cp -R dependencies/template/ocaml-base-compiler/* \
	  dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/
	{ url="$$(jq -r '.url // empty' ocaml-versions/$*.json)"; echo "url { src: \"$$url\" }"; echo "setenv: [ [ ORUN_CONFIG_ocaml_url = \"$$url\" ] ]"; } \
	  >> dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/opam
	$(eval OCAML_CONFIG_OPTION = $(shell jq -r '.configure // empty' ocaml-versions/$*.json))
	$(eval OCAML_RUN_PARAM     = $(shell jq -r '.runparams // empty' ocaml-versions/$*.json))
	opam update
	OCAMLRUNPARAM="$(OCAML_RUN_PARAM)" OCAMLCONFIGOPTION="$(OCAML_CONFIG_OPTION)" opam switch create --keep-build-dir --yes $* ocaml-base-compiler.$*
	opam pin add -n --yes --switch $* eventlog-tools https://github.com/ocaml-multicore/eventlog-tools.git#multicore
	opam pin add -n --yes --switch $* coq-core https://github.com/ejgallego/coq/archive/refs/tags/multicore-2021-09-29.tar.gz
	opam pin add -n --yes --switch $* coq-stdlib https://github.com/ejgallego/coq/archive/refs/tags/multicore-2021-09-29.tar.gz

override_packages/%: setup_sys_dune/%
	$(eval CONFIG_SWITCH_NAME = $*)
	$(eval DEV_OPAM = $(OPAMROOT)/$(CONFIG_SWITCH_NAME)/share/dev.opam)
	opam repo add upstream "https://opam.ocaml.org" --on-switch=$(CONFIG_SWITCH_NAME) --rank 2
	cp dependencies/template/dev.opam $(DEV_OPAM)
ifeq (0, $(USE_SYS_DUNE_HACK))
	opam install --switch=$(CONFIG_SWITCH_NAME) --yes "dune.$(DEFAULT_DUNE_VERSION)" "dune-configurator.$(DEFAULT_DUNE_VERSION)" "dune-private-libs.$(DEFAULT_DUNE_VERSION)" || $(CONTINUE_ON_OPAM_INSTALL_ERROR)
endif
	opam update --switch=$(CONFIG_SWITCH_NAME)
	@{ case "$*" in \
		*5.00*) sed 's/(alias (name buildbench) (deps layers.exe irmin_mem_rw.exe))/; (alias (name buildbench) (deps layers.exe irmin_mem_rw.exe))/g' ./benchmarks/irmin/dune > ./benchmarks/irmin/dune ;; \
	esac };
	@{	for i in ${PACKAGES}; do \
			sed -i "/^]/i \ \ \"$${i}\"" $(DEV_OPAM); \
		done; \
	};
	@{	declare -A OVERRIDE=( ["ocaml-config"]="\"ocaml-config\" {= \"1\"}" ); 					\
		do_overrides=`jq '.package_overrides' ocaml-versions/$*.json`; \
		if [ "$${do_overrides}" != null ]; then \
			for row in `cat ocaml-versions/$*.json | jq '.package_overrides | .[]'`; do	\
				package=`echo $$row | xargs echo | tr -d '[:space:]'`; \
				package_name=`cut -d '.' -f 1 <<< "$$package"`; \
				package_version=`cut -d '.' -f 2- <<< "$$package"`; \
				OVERRIDE["$${package_name}"]="\"$${package_name}\" {= \"$${package_version}\" }";			\
			done; 										\
		fi; \
		for key in "$${!OVERRIDE[@]}"; do 						\
                        sed -i "/\"$${key}\"/s/.*/  $${OVERRIDE[$${key}]}/" $(DEV_OPAM); \
		done; \
		do_removal=`jq '.package_remove' ocaml-versions/$*.json`; \
		if [ "$${do_removal}" != null ]; then \
			for row in `cat ocaml-versions/$*.json | jq '.package_remove | .[]'`; do \
				name=`echo $$row | xargs echo | tr -d '[:space:]'`; \
				if [ OVERRIDE["$${name}"] != null ]; then \
					sed -i "/\"$${name}\"/s/.*/ /" $(DEV_OPAM); \
				fi; \
			done; \
		fi; \
		sed -i '/^\s*$$/d' $(DEV_OPAM); \
	        opam install $(DEV_OPAM) --switch=$(CONFIG_SWITCH_NAME) --yes --deps-only;	\
		opam list --switch=$(CONFIG_SWITCH_NAME); \
	};

.PHONY: .FORCE
.FORCE:

# the file sandmark_git_hash.txt contains the current git hash for this version of sandmark
log_sandmark_hash:
	-git log -n 1

.PHONY: blah
blah:
	@echo ${PACKAGES}

ocaml-versions/%.bench: check_url depend override_packages/% log_sandmark_hash ocaml-versions/%.json .FORCE
	$(eval CONFIG_SWITCH_NAME = $*)
	$(eval CONFIG_OPTIONS      = $(shell jq -r '.configure // empty' ocaml-versions/$*.json))
	$(eval CONFIG_RUN_PARAMS   = $(shell jq -r '.runparams // empty' ocaml-versions/$*.json))
	$(eval ENVIRONMENT         = $(shell jq -r '.wrappers[] | select(.name=="$(WRAPPER)") | .environment // empty' "$(RUN_CONFIG_JSON)" ))
	@{ echo '(lang dune 1.0)'; \
	   for i in `seq 1 $(ITER)`; do \
	     echo "(context (opam (switch $(CONFIG_SWITCH_NAME)) (name $(CONFIG_SWITCH_NAME)_$$i)))"; \
	   done } > ocaml-versions/.workspace.$(CONFIG_SWITCH_NAME)
	opam exec --switch $(CONFIG_SWITCH_NAME) -- rungen _build/$(CONFIG_SWITCH_NAME)_1 $(RUN_CONFIG_JSON) > runs_dune.inc
	opam exec --switch $(CONFIG_SWITCH_NAME) -- dune build --profile=release --workspace=ocaml-versions/.workspace.$(CONFIG_SWITCH_NAME) @$(BUILD_BENCH_TARGET);
	@{ if [ "$(BUILD_ONLY)" -eq 0 ]; then												\
	        echo "Executing benchmarks with:"; 											\
	        echo "  RUN_CONFIG_JSON=${RUN_CONFIG_JSON}"; 										\
	        echo "  RUN_BENCH_TARGET=${RUN_BENCH_TARGET}  (WRAPPER=${WRAPPER})"; 							\
	        echo "  PRE_BENCH_EXEC=${PRE_BENCH_EXEC}"; 										\
	        $(PRE_BENCH_EXEC) $(ENVIRONMENT) opam exec --switch $(CONFIG_SWITCH_NAME) -- dune build -j 1 --profile=release				\
		  --workspace=ocaml-versions/.workspace.$(CONFIG_SWITCH_NAME) @$(RUN_BENCH_TARGET); ex=$$?;						\
		mkdir -p _results/;	  											\
	        for i in `seq 1 $(ITER)`; do \
			declare -A META=( ["arch"]="uname -m" ["hostname"]="hostname" ["kernel"]="uname -s" ["version"]="uname -r" ); \
			s=""; for key in "$${!META[@]}"; do \
			result=`$${META[$${key}]}`; \
			if [ "$${s}" == "" ]; then \
				s="$${key}=$${result}"; \
			else \
				s="$${s} $${key}=$${result}"; \
			fi; \
			done; \
			header_entry=`jo -p $${s} | jq -c`; \
			echo "$${header_entry}" > _results/$(CONFIG_SWITCH_NAME)_$$i.$(WRAPPER).summary.bench; \
			find _build/$(CONFIG_SWITCH_NAME)_$$i -name '*.$(WRAPPER).bench' | xargs cat >> _results/$(CONFIG_SWITCH_NAME)_$$i.$(WRAPPER).summary.bench;		\
	        done; 															\
		exit $$ex; 														\
	   else 															\
		exit 0; 														\
	   fi };

json:
	@{	output=data.json; \
		tmp=test.json; \
		count=0; \
		while read line; do \
			if [ "$${count}" -eq 0 ]; then \
				echo "$${line}" | jq '. | {config: ., results: []}' > "$${output}"; \
				count=1; \
			else \
                                bench=`echo "$${line}" | jq '. | {name: .name, command: .command, metrics: {time_secs: .time_secs, maxrss_kB: .maxrss_kB, user_time_secs: .user_time_secs, sys_time_secs: .sys_time_secs, "ocaml.version": .ocaml.version, "ocaml.c_compiler": .ocaml.c_compiler, "ocaml.architecture": .ocaml.architecture, "ocaml.word_size": .ocaml.word_size, "ocaml.system": .ocaml.system, "ocaml.stats": .ocaml.stats, "ocaml.function_sections": .ocaml.function_sections, "ocaml.supports_shared_libraries": .ocaml.supports_shared_libraries, "gc.supports_shared_libraries": .gc.allocated_words, "gc.minor_words": .gc.minor_words, "gc.promoted_words": .gc.promoted_words, "gc.major_words": .gc.major_words, "gc.minor_collections": .gc.minor_collections, "gc.major_collections": .gc.major_collections, "gc.heap_words": .gc.heap_words, "gc.top_heap_words": .gc.top_heap_words, "gc.mean_space_overhead": .gc.mean_space_overhead, codesize: .codesize, ocaml_url: .ocaml_url}}'`; \
				string=".results += [$${bench}]"; \
				jq "$${string}" "$${output}" > "$${tmp}" && mv "$${tmp}" "$${output}"; \
			fi; \
		done < _results/*.bench; \
	};

prep_bench:
	@{ 	TAG='"run_in_ci"' $(MAKE) multicore_parallel_run_config_filtered.json; \
		TAG='"macro_bench"' $(MAKE) multicore_parallel_run_config_filtered_filtered.json; \
		$(MAKE) multicore_parallel_run_config_filtered_filtered_2domains.json; \
		BUILD_BENCH_TARGET=multibench_parallel RUN_CONFIG_JSON=multicore_parallel_run_config_filtered_filtered_2domains.json $(MAKE) ocaml-versions/4.10.0+multicore.bench; \
		$(MAKE) json; \
	} > /dev/null 2>&1;

bench: prep_bench
	@cat data.json

define check_dependency
	$(if $(filter $(shell $(2) | grep $(1) | wc -l), 0),
		@echo "$(1) is not installed. $(3)")
endef

check_url:
	@{ for f in `find ocaml-versions/*.json`; do    	\
		URL=`jq -r '.url' $$f`;                   	\
		if [ -z "$$URL" ] ; then                  	\
			echo "No URL (mandatory) for $$f";   	\
		fi;                                       	\
	    done;                                        	\
	};

depend:
	$(foreach d, $(DEPENDENCIES),      $(call check_dependency, $(d), dpkg -l,   Install on Ubuntu using apt.))
	$(foreach d, $(PIP_DEPENDENCIES),  $(call check_dependency, $(d), pip3 list --format=columns, Install using pip3 install.))

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
	git restore ./benchmarks/irmin/dune

list:
	@echo $(ocamls)

list_tags:
	@echo "List of Tags"
	@jq '[.benchmarks[].tags] | add | flatten | .[]' *.json | sort -u

bash:
	bash
	@echo "[opam subshell completed]"

%_filtered.json: %.json
	jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select(.tags | index($(TAG)) != null)]}' < $< > $@

%_2domains.json: %.json
	jq '{wrappers : .wrappers, benchmarks : [.benchmarks | .[] | {executable : .executable, name: .name, tags: .tags, runs : [.runs | .[] as $$item | if ($$item | .params | split(" ") | .[0] ) == "2" then $$item | .paramwrapper |= "" else empty end ] } ] }' < $< > $@
