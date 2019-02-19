export OPAMROOT=$(CURDIR)/_opam

ocamls=$(wildcard ocaml-versions/*)

_opam:
	opam init --bare --no-setup --no-opamrc ./dependencies


bash:
	bash
	@echo "[opam subshell completed]"
