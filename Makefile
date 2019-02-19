.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

PACKAGES = \
  cpdf frama-c-base patdiff menhir minilight camlimages yojson async core \
  lwt cohttp cohttp-lwt-unix

.PHONY: bash list

ocamls=$(wildcard ocaml-versions/*.comp)


_opam:
	opam init --bare --no-setup --no-opamrc ./dependencies

_opam/%: _opam ocaml-versions/%.comp
	rm -rf dependencies/packages/ocaml/ocaml.$*
	rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	cp -R dependencies/template/ocaml dependencies/packages/ocaml/ocaml.$*
	cp -R dependencies/template/ocaml-base-compiler \
	  dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	echo "url { src: \"$$(cat ocaml-versions/$*.comp)\" }" >> \
	  dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/opam
	opam update
	opam switch create $* ocaml-base-compiler.$*

ocaml-versions/.packages.%: ocaml-versions/%.comp _opam/%
	opam update
	opam install --switch=$* --best-effort --yes $(PACKAGES)
	touch $@



list:
	@echo $(ocamls)

bash:
	bash
	@echo "[opam subshell completed]"
