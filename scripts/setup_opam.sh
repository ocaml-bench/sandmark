#!/bin/bash
# Script called before we run the benchmarks.
# Create a local opam switch with all the specific dependencies and pins.

config_switch_name=$1
sandmark_url=$2

# Clean up dependencies/packages by restoring the template
rm -rf dependencies/packages/ocaml/ocaml."$config_switch_name"
rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler."$config_switch_name"
mkdir -p dependencies/packages/ocaml/ocaml."$config_switch_name"
cp -R dependencies/template/ocaml/* dependencies/packages/ocaml/ocaml."$config_switch_name"/
mkdir -p dependencies/packages/ocaml-base-compiler/ocaml-base-compiler."$config_switch_name"
cp -R dependencies/template/ocaml-base-compiler/* \
      dependencies/packages/ocaml-base-compiler/ocaml-base-compiler."$config_switch_name"/

if [ -z "$sandmark_url" ]; then
    url=$(jq -r '.url // empty' ocaml-versions/"$config_switch_name".json);
else
    url="$sandmark_url";
fi
echo "url { src: \"$url\" }
setenv: [ [ ORUN_CONFIG_ocaml_url = \"$url\" ] ]" >> dependencies/packages/ocaml-base-compiler/ocaml-base-compiler."$config_switch_name"/opam

# Opam switch creation
opam update >/dev/null
tmp_config=$(jq -r '.configure // empty' ocaml-versions/"$config_switch_name".json)
tmp_param=$(jq -r '.runparams // empty' ocaml-versions/"$config_switch_name".json)
OCAMLRUNPARAM="$tmp_param" OCAMLCONFIGOPTION="$tmp_config" opam switch create --keep-build-dir --yes "$config_switch_name" ocaml-base-compiler."$config_switch_name" >/dev/null

# Opam pins
if [[ $config_switch_name =~ 5.1* || $config_switch_name =~ 5.2* ]]; then
    opam pin add -n --yes --switch "$config_switch_name" sexplib0.v0.15.0 https://github.com/shakthimaan/sexplib0.git#multicore >/dev/null;
fi

# TODO remove pin when a new orun version is released on opam
opam pin add -n --yes --switch "$config_switch_name" orun https://github.com/ocaml-bench/orun.git >/dev/null
# TODO remove pin when a new runtime_events_tools is released on opam
opam pin add -n --yes --switch "$config_switch_name" runtime_events_tools https://github.com/sadiqj/runtime_events_tools.git#09630b67b82f7d3226736793dd7bfc33999f4b25 >/dev/null
opam pin add -n --yes --switch "$config_switch_name" ocamlfind https://github.com/dra27/ocamlfind/archive/lib-layout.tar.gz >/dev/null
opam pin add -n --yes --switch "$config_switch_name" base.v0.14.3 https://github.com/janestreet/base.git#v0.14.3 >/dev/null
opam pin add -n --yes --switch "$config_switch_name" coq-core https://github.com/ejgallego/coq/archive/refs/tags/multicore-2021-09-29.tar.gz >/dev/null
opam pin add -n --yes --switch "$config_switch_name" coq-stdlib https://github.com/ejgallego/coq/archive/refs/tags/multicore-2021-09-29.tar.gz >/dev/null
