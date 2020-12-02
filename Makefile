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
	cpdf conf-pkg-config conf-zlib bigstringaf decompress camlzip menhirLib \
	menhir minilight base stdio dune-private-libs dune-configurator camlimages \
	yojson lwt zarith integers uuidm react ocplib-endian nbcodec checkseum \
	sexplib0 irmin-mem cubicle conf-findutils

ifeq ($(findstring multibench,$(BUILD_BENCH_TARGET)),multibench)
	PACKAGES += lockfree kcas domainslib ctypes.0.14.0+multicore
else
	PACKAGES += ctypes.0.14.0+stock frama-c coq fraplib alt-ergo js_of_ocaml-compiler
endif

DEPENDENCIES = libgmp-dev libdw-dev jq python3-pip pkg-config m4 # Ubuntu
PIP_DEPENDENCIES = intervaltree


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

ocamls=$(wildcard ocaml-versions/*.json)

# to build in a Dockerfile you need to disable sandboxing in opam
ifeq ($(OPAM_DISABLE_SANDBOXING), true)
     OPAM_INIT_EXTRA_FLAGS=--disable-sandboxing
endif
_opam/opam-init/init.sh:
	opam init --bare --no-setup --no-opamrc $(OPAM_INIT_EXTRA_FLAGS) ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.json setup_sys_dune
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

ocaml-versions/%.bench: check_url depend log_sandmark_hash ocaml-versions/%.json _opam/% .FORCE
	$(eval ENVIRONMENT = $(shell jq -r '.wrappers[] | select(.name=="$(WRAPPER)") | .environment // empty' "$(RUN_CONFIG_JSON)" ))
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
	@{ if [ "$(BUILD_ONLY)" -eq 0 ]; then												\
	echo "Executing benchmarks with:"; \
	echo "  RUN_CONFIG_JSON=${RUN_CONFIG_JSON}"; \
	echo "  RUN_BENCH_TARGET=${RUN_BENCH_TARGET}  (WRAPPER=${WRAPPER})"; \
	echo "  PRE_BENCH_EXEC=${PRE_BENCH_EXEC}"; \
		$(PRE_BENCH_EXEC) $(ENVIRONMENT) opam exec --switch $* -- dune build -j 1 --profile=release				\
		  --workspace=ocaml-versions/.workspace.$* @$(RUN_BENCH_TARGET); ex=$$?;						\
		for f in `find _build/$*_* -name '*.$(WRAPPER).bench'`; do 								\
		   d=`basename $$f | cut -d '.' -f 1,2`; 										\
		   mkdir -p _results/$*/$$d/ ; cp $$f _results/$*/$$d/; 								\
		done;															\
	        find _build/$*_* -name '*.$(WRAPPER).bench' | xargs cat > _results/$*/$*.$(WRAPPER).bench;				\
		exit $$ex; 														\
	   else 															\
		exit 0; 														\
	   fi };

define check_dependency
	$(if $(filter $(shell $(2) | grep $(1) | wc -l), 0),
		@echo "$(1) is not installed. $(3)")
endef

check_url:
	@{ for f in `find ocaml-versions/*.json`; do	\
	      URL=`jq -r '.url' $$f`;			\
	      if [ -z "$$URL" ] ; then 			\
		   echo "No URL (mandatory) for $$f";	\
	      fi; 					\
	   done;					\
	};

depend:
	$(foreach d, $(DEPENDENCIES),      $(call check_dependency, $(d), dpkg -l,   Install on Ubuntu using apt.))
	$(foreach d, $(PIP_DEPENDENCIES),  $(call check_dependency, $(d), pip3 list --format=columns, Install using pip3 install.))

clean:
	rm -rf dependencies/packages/ocaml/*
	rm -rf dependencies/packages/ocaml-base-compiler/*
	rm -rf ocaml-versions/.packages.*
	rm -rf ocaml-versions/*.bench
	rm -rf _build
	rm -rf _opam
	rm -rf _results
	rm -rf *_macro*.json *ci.json
	rm -rf *~

list:
	@echo $(ocamls)

bash:
	bash
	@echo "[opam subshell completed]"

%_filtered.json: %.json
	jq '{wrappers : .wrappers, benchmarks: [.benchmarks | .[] | select(.tags | index($(TAG)) != null)]}' < $< > $@

%_2domains.json: %.json
	jq '{wrappers : .wrappers, benchmarks : [.benchmarks | .[] | {executable : .executable, name: .name, tags: .tags, runs : [.runs | .[] as $$item | if ($$item | .params | split(" ") | .[0] ) == "2" then $$item | .paramwrapper |= "" else empty end ] } ] }' < $< > $@
