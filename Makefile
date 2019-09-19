# options for running the benchmarks

# benchmark target type:
#  - bench: single threaded
#  - parallelbench: multiple process benchmarks that only work on stock OCaml
#  - multibench: multicore threaded benchmarks that only work on OCaml multicore
BENCH_TARGET ?= bench

# number of benchmark iterations to run
ITER ?= 5

# setup default for pre benchmark wrappers
# for example PRE_BENCH_EXEC='taskset --cpu-list 3 setarch `uname -m` --addr-no-randomize'
PRE_BENCH_EXEC ?=

# option to allow benchmarks to continue even if the opam package install errored
CONTINUE_ON_OPAM_INSTALL_ERROR ?= true

PACKAGES = \
  cpdf menhir minilight camlimages yojson \
  lwt ctypes orun cil frama-c alt-ergo zarith \
  js_of_ocaml-compiler uuidm react ocplib-endian nbcodec \
  checkseum decompress

# want to handle 'multibench' and 'benchmarks/multicore-lockfree/multibench' as target
ifeq ($(findstring multibench,$(BENCH_TARGET)),multibench)
	PACKAGES += lockfree kcas
endif

.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

.PHONY: bash list clean

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

.PHONY: .FORCE
.FORCE:
ocaml-versions/%.bench: ocaml-versions/%.comp _opam/% .FORCE
	@opam update
	opam install --switch=$* --best-effort --keep-build-dir --yes $(PACKAGES) || $(CONTINUE_ON_OPAM_INSTALL_ERROR)
	$(PRE_BENCH_EXEC) opam exec --switch $* -- dune build -j 1 --profile=release $(BENCH_TARGET)
	sh run.sh $(ITER) $* $(BENCH_TARGET) orun $@

clean:
	rm -rf dependencies/packages/ocaml/*
	rm -rf dependencies/packages/ocaml-base-compiler/*
	rm -rf ocaml-versions/.packages.*
	rm -rf ocaml-versions/*.bench
	rm -rf _build
	rm -rf _opam


list:
	@echo $(ocamls)

bash:
	bash
	@echo "[opam subshell completed]"
