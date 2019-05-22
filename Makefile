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

ocamls=$(wildcard ocaml-versions/*.comp)

# to build in a Dockerfile you need to disable sandboxing in opam
ifeq ($(OPAM_DISABLE_SANDBOXING), true)
     OPAM_INIT_EXTRA_FLAGS=--disable-sandboxing
endif
_opam/opam-init/init.sh:
	opam init --bare --no-setup --no-opamrc $(OPAM_INIT_EXTRA_FLAGS) ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.comp
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
	opam switch create --yes $* ocaml-base-compiler.$*
	opam pin add -n --yes --switch $* orun orun/


.PHONY: .FORCE
.FORCE:
ocaml-versions/%.bench: ocaml-versions/%.comp _opam/% .FORCE
	@opam update
	@opam install --switch=$* --best-effort --yes $(PACKAGES) || $(CONTINUE_ON_OPAM_INSTALL_ERROR)
	@{ echo '(lang dune 1.0)'; \
	   for i in `seq 1 $(ITER)`; do \
	     echo "(context (opam (switch $*) (name $*_$$i)))"; \
           done } > ocaml-versions/.workspace.$*
	$(PRE_BENCH_EXEC) opam exec --switch $* -- dune build -j 1 --profile=release --workspace=ocaml-versions/.workspace.$* @$(BENCH_TARGET); \
	  ex=$$?; find _build/$*_* -name '*.bench' | xargs cat > $@; exit $$ex


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
