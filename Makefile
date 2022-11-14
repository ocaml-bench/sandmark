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
SANDMARK_DUNE_VERSION ?= 2.9.0

# Default URL
SANDMARK_URL ?= ""

# Default packages to remove
SANDMARK_REMOVE_PACKAGES ?= ""

# Default list of packages to override
SANDMARK_OVERRIDE_PACKAGES ?= ""

# Override orun with custom name
SANDMARK_CUSTOM_NAME ?= ""

# Flag to select whether to use sys_dune_hack
USE_SYS_DUNE_HACK ?= 0

# benchmark run target type:
#  run_<wrapper> where wrapper is one of the wrappers defined in
#  RUN_CONFIG_JSON. The default RUN_CONFIG_JSON defines two wrappers: perfstat
#  and orun
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

# option to wait for loadavg to settle down once the dependencies are installed and
# before the benchmarks are executed
OPT_WAIT ?= 1

# The time when the wait for the loadavg to decrease begins
START_TIME ?=

IRMIN_DATA_DIR=/tmp/irmin-data

WRAPPER = $(patsubst run_%,%,$(RUN_BENCH_TARGET))

PACKAGES = sexplib0 re yojson react uuidm cpdf nbcodec minilight cubicle orun rungen

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
	$(eval CONFIG_SWITCH_NAME = $*)
	$(eval OVERRIDE_DUNE = $(shell sed -n 's/.*dune\.\([0-9]\.[0-9]\.[0-9]\).*/\1/p' ocaml-versions/$*.json))
	$(if $(strip $(OVERRIDE_DUNE)),					\
		$(eval SANDMARK_DUNE_VERSION = "$(OVERRIDE_DUNE)")	\
		@echo "Overriding dune with "$(SANDMARK_DUNE_VERSION),	\
		@echo "Using default dune.$(SANDMARK_DUNE_VERSION)")
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
	opam install --switch=$(CONFIG_SWITCH_NAME) --yes "dune.$(SANDMARK_DUNE_VERSION)" "dune-configurator.$(SANDMARK_DUNE_VERSION)"
endif

ocamls=$(wildcard ocaml-versions/*.json)

_opam/opam-init/init.sh:
	opam init --bare --no-setup --no-opamrc --disable-sandboxing ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.json
	$(eval CONFIG_SWITCH_NAME = $*)
	rm -rf dependencies/packages/ocaml/ocaml.$*
	rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	mkdir -p dependencies/packages/ocaml/ocaml.$*
	cp -R dependencies/template/ocaml/* dependencies/packages/ocaml/ocaml.$*/
	mkdir -p dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	cp -R dependencies/template/ocaml-base-compiler/* \
	  dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/
	{	if [ "$(SANDMARK_URL)" == "" ]; then	\
			url="$$(jq -r '.url // empty' ocaml-versions/$*.json)"; \
		else \
			url="$(SANDMARK_URL)"; \
		fi; \
		echo "url { src: \"$$url\" }"; echo "setenv: [ [ ORUN_CONFIG_ocaml_url = \"$$url\" ] ]"; } \
	>> dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/opam;
	$(eval OCAML_CONFIG_OPTION = $(shell jq -r '.configure // empty' ocaml-versions/$*.json))
	$(eval OCAML_RUN_PARAM     = $(shell jq -r '.runparams // empty' ocaml-versions/$*.json))
	opam update
	OCAMLRUNPARAM="$(OCAML_RUN_PARAM)" OCAMLCONFIGOPTION="$(OCAML_CONFIG_OPTION)" opam switch create --keep-build-dir --yes $* ocaml-base-compiler.$*
	@{ case "$*" in \
		*5.1*) opam pin add -n --yes --switch $* sexplib0.v0.15.0 https://github.com/shakthimaan/sexplib0.git#multicore; \
	esac };
	opam pin add -n --yes --switch $* runtime_events_tools https://github.com/Firobe/runtime_events_tools.git
	opam pin add -n --yes --switch $* hdr_histogram https://github.com/Firobe/hdr_histogram_ocaml.git
	opam pin add -n --yes --switch $* ocamlfind https://github.com/dra27/ocamlfind/archive/lib-layout.tar.gz
	opam pin add -n --yes --switch $* base.v0.14.3 https://github.com/janestreet/base.git#v0.14.3
	opam pin add -n --yes --switch $* coq-core https://github.com/ejgallego/coq/archive/refs/tags/multicore-2021-09-29.tar.gz
	opam pin add -n --yes --switch $* coq-stdlib https://github.com/ejgallego/coq/archive/refs/tags/multicore-2021-09-29.tar.gz

override_packages/%: setup_sys_dune/%
	$(eval CONFIG_SWITCH_NAME = $*)
	$(eval DEV_OPAM = $(OPAMROOT)/$(CONFIG_SWITCH_NAME)/share/dev.opam)
	@{ case "$*" in \
		*5.1.0*) cp dependencies/template/dev-5.1.0+trunk.opam $(DEV_OPAM) ;; \
		*) cp dependencies/template/dev.opam $(DEV_OPAM) ;; \
	esac };
	opam repo add upstream "git+https://github.com/ocaml/opam-repository.git" --on-switch=$(CONFIG_SWITCH_NAME) --rank 2
	opam repo add alpha git+https://github.com/kit-ty-kate/opam-alpha-repository.git --on-switch=$(CONFIG_SWITCH_NAME) --rank 2
	opam exec --switch $(CONFIG_SWITCH_NAME) -- opam update
	opam install --switch=$(CONFIG_SWITCH_NAME) --yes "lru" "psq"
	opam exec --switch $(CONFIG_SWITCH_NAME) -- opam list
ifeq (0, $(USE_SYS_DUNE_HACK))
	opam install --switch=$(CONFIG_SWITCH_NAME) --yes "dune.$(SANDMARK_DUNE_VERSION)" "dune-configurator.$(SANDMARK_DUNE_VERSION)" "dune-private-libs.$(SANDMARK_DUNE_VERSION)" || $(CONTINUE_ON_OPAM_INSTALL_ERROR)
endif
	opam update --switch=$(CONFIG_SWITCH_NAME)
	@{ case "$*" in \
		*5.1*) sed 's/(alias (name buildbench) (deps layers.exe irmin_mem_rw.exe))/; (alias (name buildbench) (deps layers.exe irmin_mem_rw.exe))/g' ./benchmarks/irmin/dune > ./benchmarks/irmin/dune ; \
			sed 's/(alias (name buildbench) (deps metro_geo.pdf PDFReference16.pdf_toobig))/; (alias (name buildbench) (deps metro_geo.pdf PDFReference16.pdf_toobig))/g' ./benchmarks/cpdf/dune ;; \
	esac };
	@{	for i in ${PACKAGES}; do \
			sed -i "/^]/i \ \ \"$${i}\"" $(DEV_OPAM); \
		done; \
	};
	@{	declare -A OVERRIDE=( ["ocaml-config"]="\"ocaml-config\" {= \"1\"}" );	\
		if [ -z "$(SANDMARK_OVERRIDE_PACKAGES)" ]; then \
			do_overrides=`jq '.package_overrides' ocaml-versions/$*.json`; \
			if [ "$${do_overrides}" != null ]; then \
				for row in `cat ocaml-versions/$*.json | jq '.package_overrides | .[]'`; do	\
					package=`echo $$row | xargs echo | tr -d '[:space:]'`; \
					package_name=`cut -d '.' -f 1 <<< "$$package"`; \
					package_version=`cut -d '.' -f 2- <<< "$$package"`; \
					OVERRIDE["$${package_name}"]="\"$${package_name}\" {= \"$${package_version}\" }";	\
				done;	\
			fi; \
		else \
			for p in ${SANDMARK_OVERRIDE_PACKAGES}; do \
				package="$${p}"; \
				package_name=`cut -d '.' -f 1 <<< "$${package}"`; \
				package_version=`cut -d '.' -f 2- <<< "$${package}"`; \
				OVERRIDE["$${package_name}"]="\"$${package_name}\" {= \"$${package_version}\" }"; \
			done; \
		fi; \
		for key in "$${!OVERRIDE[@]}"; do						\
			sed -i "/\"$${key}\"/s/.*/  $${OVERRIDE[$${key}]}/" $(DEV_OPAM); \
		done; \
		if [ -z "$(SANDMARK_REMOVE_PACKAGES)" ]; then \
			do_removal=`jq '.package_remove' ocaml-versions/$*.json`; \
			if [ "$${do_removal}" != null ]; then \
				for row in `cat ocaml-versions/$*.json | jq '.package_remove | .[]'`; do \
					name=`echo $$row | xargs echo | tr -d '[:space:]'`; \
					if [ OVERRIDE["$${name}"] != null ]; then \
						sed -i "/\"$${name}\"/s/.*/ /" $(DEV_OPAM); \
					fi; \
				done; \
			fi; \
		else \
			for p in ${SANDMARK_REMOVE_PACKAGES}; do \
				if [ OVERRIDE["$${p}"] != null ]; then \
					sed -i "/\"$${p}\"/s/.*/ /" $(DEV_OPAM); \
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

ocaml-versions/%.bench: depend filter/% override_packages/% log_sandmark_hash ocaml-versions/%.json .FORCE
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
		echo "Executing benchmarks with:";											\
		echo "  RUN_CONFIG_JSON=${RUN_CONFIG_JSON}";										\
		echo "  RUN_BENCH_TARGET=${RUN_BENCH_TARGET}  (WRAPPER=${WRAPPER})";							\
		echo "  PRE_BENCH_EXEC=${PRE_BENCH_EXEC}";										\
		$(PRE_BENCH_EXEC) $(ENVIRONMENT) opam exec --switch $(CONFIG_SWITCH_NAME) -- dune build -j 1 --profile=release				\
		  --workspace=ocaml-versions/.workspace.$(CONFIG_SWITCH_NAME) @$(RUN_BENCH_TARGET); ex=$$?;						\
		mkdir -p _results/;												\
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
			echo "$${header_entry}" > _results/$(SANDMARK_CUSTOM_NAME)_$$i.$(WRAPPER).summary.bench; \
			find _build/$(CONFIG_SWITCH_NAME)_$$i -name '*.$(WRAPPER).bench' | xargs cat >> _results/$(SANDMARK_CUSTOM_NAME)_$$i.$(WRAPPER).summary.bench;		\
		done;															\
		exit $$ex;														\
	   else																\
		exit 0;															\
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
	@{	$(BENCH_COMMAND); \
		$(MAKE) json; \
	};

bench: prep_bench
	@cat data.json

define check_dependency
	$(if $(filter $(shell $(2) | grep $(1) | wc -l), 0),
		@echo "$(1) is not installed. $(3)")
endef

check_jq:
	@{ for f in `find ocaml-versions/*.json`; do		\
		RESULT=`jq . $$f > /dev/null 2>&1; echo $$?`;	\
		if [ "$${RESULT}" != 0 ]; then			\
			echo "Error: jq parsing error in $$f";	\
			exit 1;					\
		fi;						\
	    done;						\
	};

check_url: check_jq
	@{ for f in `find ocaml-versions/*.json`; do					\
		HEAD=`head -1 $$f`;							\
		if [ "$$HEAD" == "{" ]; then						\
			URL=`jq -r '.url' $$f`;						\
			if [ -z "$$URL" ] ; then					\
				echo "No URL (mandatory) for $$f";			\
			else								\
				URL_EXISTS=`wget --spider $$URL 2>/dev/null; echo $$?`; \
				if [ "$${URL_EXISTS}" != 0 ]; then			\
					echo "Error: URL $$URL does not exist";		\
				fi;							\
			fi;								\
		else									\
			URLS=`jq -r .[].url $$f`;					\
			for u in "$$URLS"; do						\
				URL_EXISTS=`wget --spider $$u 2>/dev/null; echo $$?`;	\
				if [ "$${URL_EXISTS}" != 0 ]; then			\
					echo "Error: URL $$u does not exist";		\
				fi;							\
			done;								\
		fi;									\
	    done;									\
	};

load_irmin_data:
	mkdir -p /tmp/irmin_trace_replay_artefacts;
	if [ ! -f $(IRMIN_DATA_DIR)/data4_100066commits.repr ]; then \
		wget http://data.tarides.com/irmin/data4_100066commits.repr -P $(IRMIN_DATA_DIR); \
	fi;


load_check:
	$(eval START_TIME = $(shell date +%s))
	@./loadavg.sh $(OPT_WAIT) $(START_TIME)

filter/%:
	$(eval CONFIG_SWITCH_NAME = $*)
	$(eval CONFIG_VARIANT = $(shell echo $(CONFIG_SWITCH_NAME) | grep -oP '([0-9]|\.)*'  ))
	@echo $(CONFIG_VARIANT)
	if [ $(CONFIG_VARIANT) = "5.1.0" ]; then \
		echo "Filtering some benchmarks for OCaml v5.1.0"; \
		jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select( .name as $$name | ["irmin_replay", "cpdf", "frama-c", "mergesort", "js_of_ocaml", "graph500_par_gen"] | index($$name) | not )]}' $(RUN_CONFIG_JSON) > $(RUN_CONFIG_JSON).tmp; \
		mv $(RUN_CONFIG_JSON).tmp $(RUN_CONFIG_JSON); \
	fi;

depend: check_url load_check
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
	git clean -fd dependencies/packages/ocaml-base-compiler dependencies/packages/ocaml
	git restore ./benchmarks/cpdf/dune

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
