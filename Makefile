.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

# FIXME: include frama-c-base, alt-ergo
PACKAGES = \
  cpdf menhir minilight camlimages yojson  \
  lwt ctypes orun cil \
  js_of_ocaml-compiler uuidm react ocplib-endian nbcodec

.PHONY: bash list clean

ocamls=$(wildcard ocaml-versions/*.comp)


_opam/config:
	opam init --bare --no-setup --no-opamrc ./dependencies

_opam/%: _opam/config ocaml-versions/%.comp
	rm -rf dependencies/packages/ocaml/ocaml.$*
	rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	cp -R dependencies/template/ocaml dependencies/packages/ocaml/ocaml.$*
	cp -R dependencies/template/ocaml-base-compiler \
	  dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	{ url="$$(cat ocaml-versions/$*.comp)"; echo "url { src: \"$$url\" }"; echo "setenv: [ [ ORUN_CONFIG_ocaml_url = \"$$url\" ] ]"; } \
	  >> dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/opam
	opam update
	opam switch create $* ocaml-base-compiler.$*
	opam pin add -n --yes --switch $* orun orun/

ocaml-versions/.packages.%: ocaml-versions/%.comp _opam/%
	opam update
	opam install --switch=$* --best-effort --yes $(PACKAGES)
	touch $@

.PHONY: .FORCE
.FORCE:
ocaml-versions/%.bench: ocaml-versions/.packages.% .FORCE
	{ echo '(lang dune 1.0)'; echo '(context (opam (switch $*)))'; } > ocaml-versions/.workspace.%
	opam exec --switch $* -- dune build -j 1 --profile=release --workspace=ocaml-versions/.workspace.% @bench
	find _build/$* -name '*.bench' | xargs cat > $@


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
