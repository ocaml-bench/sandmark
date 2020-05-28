# options for running the benchmarks
#
# paramwrapper for passing taskset and chrt details
PARAMWRAPPER ?= $(nullstring)

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

# number of benchmark iterations to run
ITER ?= 1

# setup default for pre benchmark wrappers
# for example PRE_BENCH_EXEC='taskset --cpu-list 3 setarch `uname -m` --addr-no-randomize'
PRE_BENCH_EXEC ?=

# option to allow benchmarks to continue even if the opam package install errored
CONTINUE_ON_OPAM_INSTALL_ERROR ?= true

WRAPPER = $(subst run_,,$(RUN_BENCH_TARGET))

PACKAGES = \
	cpdf menhir minilight camlimages yojson lwt alt-ergo zarith \
	js_of_ocaml-compiler uuidm react ocplib-endian nbcodec checkseum decompress \
	sexplib0 irmin-mem cubicle

DEPENDENCIES = libgmp-dev libdw-dev jq python3-pip # Ubuntu
PIP_DEPENDENCIES = intervaltree

# want to handle 'multibench' and 'benchmarks/multicore-lockfree/multibench' as target
ifeq ($(findstring multibench,$(BUILD_BENCH_TARGET)),multibench)
	PACKAGES += lockfree kcas domainslib ctypes.0.14.0+multicore
else ## ctypes and frama-c do not build under multicore
	PACKAGES += ctypes.0.14.0+stock frama-c
endif

.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

.PHONY: bash list depend clean

# HACK: we are using the system installed dune to avoid breakages with
# multicore and 4.09/trunk
# This is a workaround for r14/4.09/trunk until better solutions arrive
SYS_DUNE_BASE_DIR ?= $(subst /bin/dune,,$(shell which dune))

setup_sys_dune:
ifeq (,$(SYS_DUNE_BASE_DIR))
	$(error Could not find a system installation of dune (try `opam install dune`?))
else
	@echo "Linking to system dune files found at: "$(SYS_DUNE_BASE_DIR)
	@echo $(SYS_DUNE_BASE_DIR)"/bin/dune --version = "$(shell $(SYS_DUNE_BASE_DIR)/bin/dune --version)
	@rm -rf $(CURDIR)/_opam/sys_dune
	@mkdir -p $(CURDIR)/_opam/sys_dune/bin
	@mkdir -p $(CURDIR)/_opam/sys_dune/lib
	ln -s $(SYS_DUNE_BASE_DIR)/bin/dune $(CURDIR)/_opam/sys_dune/bin/dune
	ln -s $(SYS_DUNE_BASE_DIR)/bin/jbuilder $(CURDIR)/_opam/sys_dune/bin/jbuilder
	ln -s $(SYS_DUNE_BASE_DIR)/lib/dune $(CURDIR)/_opam/sys_dune/lib/dune
endif

ocamls=$(wildcard ocaml-versions/*.comp)

# to build in a Dockerfile you need to disable sandboxing in opam
ifeq ($(OPAM_DISABLE_SANDBOXING), true)
     OPAM_INIT_EXTRA_FLAGS=--disable-sandboxing
endif
_opam/opam-init/init.sh:
	opam init --bare --no-setup --no-opamrc $(OPAM_INIT_EXTRA_FLAGS) ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.comp setup_sys_dune
	rm -rf dependencies/packages/ocaml/ocaml.$*
	rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	mkdir -p dependencies/packages/ocaml/ocaml.$*
	cp -R dependencies/template/ocaml/* dependencies/packages/ocaml/ocaml.$*/
	mkdir -p dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	cp -R dependencies/template/ocaml-base-compiler/* \
	  dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/
	{ url="$$(cat ocaml-versions/$*.comp)"; echo "url { src: \"$$url\" }"; echo "setenv: [ [ ORUN_CONFIG_ocaml_url = \"$$url\" ] ]"; } \
	  >> dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/opam
	opam update
	opam switch create --keep-build-dir --yes $* ocaml-base-compiler.$*
	opam pin add -n --yes --switch $* orun orun/
	opam pin add -n --yes --switch $* rungen rungen/


.PHONY: .FORCE
.FORCE:

# the file sandmark_git_hash.txt contains the current git hash for this version of sandmark
log_sandmark_hash:
	-git log -n 1

.PHONY: blah
blah:
	@echo ${PACKAGES}

ocaml-versions/%.bench: depend log_sandmark_hash ocaml-versions/%.comp _opam/% .FORCE
	@opam update
	opam install --switch=$* --keep-build-dir --yes rungen orun
	opam install --switch=$* --best-effort --keep-build-dir --yes $(PACKAGES) || $(CONTINUE_ON_OPAM_INSTALL_ERROR)
	@{ echo '(lang dune 1.0)'; \
	   for i in `seq 1 $(ITER)`; do \
	     echo "(context (opam (switch $*) (name $*_$$i)))"; \
	   done } > ocaml-versions/.workspace.$*
	opam exec --switch $* -- cp pausetimes/* $$(opam config var bin)
	opam exec --switch $* -- rungen _build/$*_1 $(RUN_CONFIG_JSON) > runs_dune.inc;
	opam exec --switch $* -- dune build --profile=release --workspace=ocaml-versions/.workspace.$* @$(BUILD_BENCH_TARGET);
	@{ IS_PARALLEL=`grep -c chrt $(RUN_CONFIG_JSON)`; 									\
	   if [ "$$IS_PARALLEL" -gt 0 ]; then											\
	     $(PRE_BENCH_EXEC) sudo -s OPAMROOT="${OPAMROOT}" OPAMROOTISOK="true" BUILD_BENCH_TARGET="${BUILD_BENCH_TARGET}" 	\
               RUN_BENCH_TARGET="${RUN_BENCH_TARGET}" RUN_CONFIG_JSON="${RUN_CONFIG_JSON}" opam exec --switch $* -- 		\
	       dune build -j 1 --profile=release --workspace=ocaml-versions/.workspace.$* @$(RUN_BENCH_TARGET); ex=$$?; 	\
	   else															\
	     $(PRE_BENCH_EXEC) opam exec --switch $* -- dune build -j 1 --profile=release 					\
	       --workspace=ocaml-versions/.workspace.$* @$(RUN_BENCH_TARGET); ex=$$?;						\
	   fi };
	@{ for f in `find _build/$*_* -name '*.bench'`; do \
	   d=`basename $$f | cut -d '.' -f 1,2`; \
	   mkdir -p _results/$*/$$d/ ; cp $$f _results/$*/$$d/; \
	done };
	@{ find _build/$*_* -name '*.$(WRAPPER).bench' | xargs cat > _results/$*/$*.$(WRAPPER).bench; };
	exit $$ex;

define check_dependency
	$(if $(filter $(shell $(2) | grep $(1) | wc -l), 0),
		@echo "$(1) is not installed. $(3)")
endef

depend:
	$(foreach d, $(DEPENDENCIES),     $(call check_dependency, $(d), dpkg -l,   Install on Ubuntu using apt.))
	$(foreach d, $(PIP_DEPENDENCIES), $(call check_dependency, $(d), pip3 list --format=columns, Install using pip3 install.))

clean:
	rm -rf dependencies/packages/ocaml/*
	rm -rf dependencies/packages/ocaml-base-compiler/*
	rm -rf ocaml-versions/.packages.*
	rm -rf ocaml-versions/*.bench
	rm -rf _build
	rm -rf _opam
	rm -rf _results

list:
	@echo $(ocamls)

bash:
	bash
	@echo "[opam subshell completed]"

%_macro.json: %.json
	jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select(.ismacrobench == true)]}' < $< > $@

%_macro_parallel.json: %_macro.json
	jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select(.ismacrobench == true)]} | {wrappers : .wrappers, benchmarks : [.benchmarks | .[] | select(.ismacrobench == true) | {executable : .executable, name: .name, ismacrobench: .ismacrobench, runs : [.runs | .[] as $$item | if ($$item | .params | split(" ") | .[0] ) == "2" then $$item | .paramwrapper |= "" else empty end ] } ]}' < $< > $@
