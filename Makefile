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

PACKAGES = decompress irmin-mem zarith bigstringaf num lwt react uuidm cpdf menhir menhirLib

ifeq ($(findstring multibench,$(BUILD_BENCH_TARGET)),multibench)
	PACKAGES += #lockfree kcas domainslib ctypes.0.14.0+multicore
else
	PACKAGES += fraplib coq.dev #ctypes.0.14.0+stock frama-c coq fraplib alt-ergo js_of_ocaml-compiler
endif

DEPENDENCIES = libgmp-dev libdw-dev jq jo python3-pip pkg-config m4 # Ubuntu
PIP_DEPENDENCIES = intervaltree

%_filtered.json: %.json
	jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select(.tags | index($(TAG)) != null)]}' < $< > $@

%_2domains.json: %.json
	jq '{wrappers : .wrappers, benchmarks : [.benchmarks | .[] | {executable : .executable, name: .name, tags: .tags, runs : [.runs | .[] as $$item | if ($$item | .params | split(" ") | .[0] ) == "2" then $$item | .paramwrapper |= "" else empty end ] } ] }' < $< > $@

#
# Build
#

define check_dependency
	$(if $(filter $(shell $(2) | grep $(1) | wc -l), 0),
		@echo "$(1) is not installed. $(3)")
endef

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

ocaml-versions/%.bench: depend log_sandmark_hash ocaml-versions/%.json .FORCE
	$(eval CONFIG_SWITCH_INPUT = $(shell jq -r '.name' ocaml-versions/$*.json))
	$(eval CONFIG_SWITCH_NAME  = $(shell jq -r '.name | sub(":"; "-") | sub("/"; "-")' ocaml-versions/$*.json))
	$(eval CONFIG_OPTIONS      = $(shell jq -r '.configure // empty' ocaml-versions/$*.json))
	$(eval CONFIG_RUN_PARAMS   = $(shell jq -r '.runparams // empty' ocaml-versions/$*.json))
	$(eval ENVIRONMENT         = $(shell jq -r '.wrappers[] | select(.name=="$(WRAPPER)") | .environment // empty' "$(RUN_CONFIG_JSON)" ))
	opam update
	@{ if [ -f "$(HOME)/.opam/plugins/bin/opam-compiler" ]; then		\
		echo "$(HOME)/.opam/plugins/bin/opam-compiler exists!";		\
	   else									\
		opam install opam-compiler --best-effort --yes; 	 	\
	   fi; };
	@{ SWITCH_EXISTS=`opam switch list -s | grep -c $(CONFIG_SWITCH_NAME)`;								\
	   if [ "$$SWITCH_EXISTS" -eq 1 ]; then												\
		opam switch $(CONFIG_SWITCH_NAME);											\
	   else																\
		OCAMLRUNPARAM="$(CONFIG_RUN_PARAMS)" OCAMLCONFIGOPTION="$(CONFIG_OPTIONS)" opam compiler create $(CONFIG_SWITCH_INPUT);	\
	   fi; };
	opam install rungen orun
	@{ LOCAL_REPO_EXISTS=`opam repo -s | grep -c local`; 	\
	   if [ "$$LOCAL_REPO_EXISTS" -eq 0 ]; then		\
	     opam repo add local dependencies;			\
           fi; };
	opam install --switch=$(CONFIG_SWITCH_NAME) --best-effort --keep-build-dir --yes $(PACKAGES) || $(CONTINUE_ON_OPAM_INSTALL_ERROR)
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
			find _build/$(CONFIG_SWITCH_NAME)_$$i -name '*.bench' -exec rm -f {} \;; 								\
	        done; 															\
		exit $$ex; 														\
	   else 															\
		exit 0; 														\
	   fi };

clean:
	rm -rf ocaml-versions/.workspace.*
	rm -rf _build
	rm -rf *~
	rm -f *filtered.json
	rm -f *.inc
