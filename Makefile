#
# Configuration
#

# Use bash
SHELL=/bin/bash

# options for running the benchmarks
# benchmark build target type:
#  - buildbench: build all single threaded tests
BUILD_BENCH_TARGET ?= buildbench

# The run configuration json file that describes the benchmarks and
# configurations.
RUN_CONFIG_JSON ?= run_config.json

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

PACKAGES = \
	dune sexplib0 re yojson decompress irmin-mem zarith bigstringaf \
	num lwt react uuidm cpdf menhir menhirLib ocaml-config nbcodec minilight cubicle

ifeq ($(findstring multibench,$(BUILD_BENCH_TARGET)),multibench)
	PACKAGES += lockfree domainslib kcas # ctypes.0.14.0+multicore
else
	PACKAGES += fraplib frama-c coq alt-ergo #ctypes.0.14.0+stock  js_of_ocaml-compiler
endif

DEPENDENCIES = libgmp-dev libdw-dev jq jo python3-pip pkg-config m4 autoconf # Ubuntu
PIP_DEPENDENCIES = intervaltree

.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

.PHONY: bash list depend clean

ocamls=$(wildcard ocaml-versions/*.json)

%_filtered.json: %.json
	jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select(.tags | index($(TAG)) != null)]}' < $< > $@

%_2domains.json: %.json
	jq '{wrappers : .wrappers, benchmarks : [.benchmarks | .[] | {executable : .executable, name: .name, tags: .tags, runs : [.runs | .[] as $$item | if ($$item | .params | split(" ") | .[0] ) == "2" then $$item | .paramwrapper |= "" else empty end ] } ] }' < $< > $@

#
# Build
#

list_tags:
	@echo "List of Tags"
	@jq '[.benchmarks[].tags] | add | flatten | .[]' *.json | sort -u

override_packages/%: _opam/%
	$(eval CONFIG_SWITCH_NAME = $*)
	$(eval DEV_OPAM = $(OPAMROOT)/$(CONFIG_SWITCH_NAME)/share/dev.opam)
	opam repo add upstream "https://opam.ocaml.org" --on-switch=$(CONFIG_SWITCH_NAME) --rank 2
	cp dependencies/template/dev.opam $(DEV_OPAM)
	opam install --switch=$(CONFIG_SWITCH_NAME) --yes "dune.2.6.0" || $(CONTINUE_ON_OPAM_INSTALL_ERROR)
	opam update --switch=$(CONFIG_SWITCH_NAME)
	@{	declare -A OVERRIDE=( ["dune"]="\"dune\" {= \"2.6.0\"}" ); 					\
		do_overrides=`jq '.package_overrides' ocaml-versions/$*.json`; \
		if [ "$${do_overrides}" != null ]; then \
			for row in `cat ocaml-versions/$*.json | jq '.package_overrides | .[]'`; do	\
				package=`echo $$row | xargs echo | tr -d '[:space:]'`; \
				package_name=`cut -d '.' -f 1 <<< "$$package"`; \
				package_version=`cut -d '.' -f 2- <<< "$$package"`; \
				OVERRIDE["$${package_name}"]="\"$${package_name}\" {= \"$${package_version}\" }";			\
			done; 										\
		fi; \
		for i in ${PACKAGES}; do 							\
			if [ -v $${OVERRIDE["$${i}"]} ]; then 					\
				OVERRIDE["$${i}"]="\"$${i}\""; 					\
			fi; 									\
		done; 										\
		for key in "$${!OVERRIDE[@]}"; do 						\
			echo " $${OVERRIDE[$${key}]}" >> $(DEV_OPAM); 	\
		done; 										\
		echo "]" >> $(DEV_OPAM); 	\
	        opam install $(DEV_OPAM) --switch=$(CONFIG_SWITCH_NAME) --yes --deps-only || $(CONTINUE_ON_OPAM_INSTALL_ERROR);	\
		opam list --switch=$(CONFIG_SWITCH_NAME); \
	};

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

.PHONY: .FORCE
.FORCE:

# the file sandmark_git_hash.txt contains the current git hash for this version of sandmark
log_sandmark_hash:
	-git log -n 1

.PHONY: blah
blah:
	@echo ${PACKAGES}

list:
	@echo $(ocamls)

bash:
	bash
	@echo "[opam subshell completed]"

# to build in a Dockerfile you need to disable sandboxing in opam
ifeq ($(OPAM_DISABLE_SANDBOXING), true)
	OPAM_INIT_EXTRA_FLAGS=--disable-sandboxing
endif
_opam/opam-init/init.sh:
	opam init --bare --no-setup --no-opamrc $(OPAM_INIT_EXTRA_FLAGS) ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.json
	rm -rf dependencies/packages/ocaml/ocaml.$*
	rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	mkdir -p dependencies/packages/ocaml/ocaml.$*
	cp -R dependencies/template/ocaml/* dependencies/packages/ocaml/ocaml.$*/
	mkdir -p dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	cp -R dependencies/template/ocaml-base-compiler/* \
          dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/
	{ url="$$(jq -r '.url // empty' ocaml-versions/$*.json)"; echo "url { src: \"$$url\" }"; echo "setenv: [ [ ORUN_CONFIG_ocaml_url = \"$$url\" ] ]"; } \
\
          >> dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/opam
	$(eval OCAML_CONFIG_OPTION = $(shell jq -r '.configure // empty' ocaml-versions/$*.json))
	$(eval OCAML_RUN_PARAM     = $(shell jq -r '.runparams // empty' ocaml-versions/$*.json))
	opam update
	OCAMLRUNPARAM="$(OCAML_RUN_PARAM)" OCAMLCONFIGOPTION="$(OCAML_CONFIG_OPTION)" opam switch create --keep-build-dir --yes $* ocaml-base-compiler.$*

ocaml-versions/%.bench: check_url depend override_packages/% log_sandmark_hash ocaml-versions/%.json .FORCE
	$(eval CONFIG_SWITCH_NAME = $*)
	$(eval CONFIG_OPTIONS      = $(shell jq -r '.configure // empty' ocaml-versions/$*.json))
	$(eval CONFIG_RUN_PARAMS   = $(shell jq -r '.runparams // empty' ocaml-versions/$*.json))
	$(eval ENVIRONMENT         = $(shell jq -r '.wrappers[] | select(.name=="$(WRAPPER)") | .environment // empty' "$(RUN_CONFIG_JSON)" ))
	opam pin add -n --yes --switch $(CONFIG_SWITCH_NAME) orun ../orun/
	opam pin add -n --yes --switch $(CONFIG_SWITCH_NAME) rungen ../rungen/
	opam install --switch=$(CONFIG_SWITCH_NAME) --yes rungen orun
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
			fi \
			done; \
			header_entry=`jo -p $${s} | jq -c`; \
			echo "$${header_entry}" > _results/$(CONFIG_SWITCH_NAME)_$$i.$(WRAPPER).summary.bench; \
			find _build/$(CONFIG_SWITCH_NAME)_$$i -name '*.$(WRAPPER).bench' | xargs cat >> _results/$(CONFIG_SWITCH_NAME)_$$i.$(WRAPPER).summary.bench;		\
	        done; 															\
		exit $$ex; 														\
	   else 															\
		exit 0; 														\
	   fi };

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

