#!/bin/bash
# Script called before we run the benchmarks.
# HACK: we are using the system installed dune to avoid breakages with
# multicore and 4.09/trunk
# This is a workaround for r14/4.09/trunk until better solutions arrive

config_switch_name=$1
sandmark_dune_version=$2
use_sys_dune_hack=$3

sys_dune_base_dir=$(which dune | sed -n 's|\(.*\)/bin/dune|\1|p' -)

override_dune=$(sed -n 's/.*dune\.\([0-9]\.[0-9]\.[0-9]\).*/\1/p' ocaml-versions/"$config_switch_name".json)

if [ "$override_dune" ]; then
    sandmark_dune_version="$override_dune";
    echo "Overriding dune with $sandmark_dune_version";
    echo "Using default dune.$sandmark_dune_version";
fi;

if "$use_sys_dune_hack"; then
    echo "Linking to system dune files found at: $sys_dune_base_dir"
	echo "$sys_dune_base_dir/bin/dune --version = $("$sys_dune_base_dir"/bin/dune --version)"
	rm -rf ./_opam/sys_dune
	mkdir -p ./_opam/sys_dune/bin
	mkdir -p ./_opam/sys_dune/lib
	ln -s "$sys_dune_base_dir"/bin/dune ./_opam/sys_dune/bin/dune
	ln -s "$sys_dune_base_dir"/bin/jbuilder ./_opam/sys_dune/bin/jbuilder
	ln -s "$sys_dune_base_dir"/lib/dune ./_opam/sys_dune/lib/dune
	opam repo add upstream "git+https://github.com/ocaml/opam-repository.git" --on-switch="$config_switch_name" --rank 2
	opam install --switch="$config_switch_name" --yes ocamlfind
	opam install --switch="$config_switch_name" --yes "dune.$sandmark_dune_version" "dune-configurator.$sandmark_dune_version"
	# Pin the version so it doesn't change when installing packages
	opam pin add --switch="$config_switch_name" --yes -n dune "$sandmark_dune_version"
fi