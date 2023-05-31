#!/bin/bash
# Script called before we run the benchmarks.

config_switch_name=$1
opam_root=$2
packages=$3
use_sys_dune_hack=$4
sandmark_dune_version=$5
continue_on_opam_install_error=$6
sandmark_override_packages=$7
sandmark_remove_packages=$8

dev_opam=$opam_root/$config_switch_name/share/dev.opam

# Retrieve set of version constraints for chosen OCaml version
case "$config_switch_name" in
    *5.2.0*)
        echo "Using template/dev-5.2.0+trunk.opam" && cp dependencies/template/dev-5.2.0+trunk.opam "$dev_opam" ;;
    *5.1.0*)
        echo "Using template/dev-5.1.0+trunk.opam" && cp dependencies/template/dev-5.1.0+trunk.opam "$dev_opam" ;;
    *5.0.1*)
        echo "Using template/dev-5.0.1+trunk.opam" && cp dependencies/template/dev-5.0.0+trunk.opam "$dev_opam" ;;
    *4.14*)
        echo "Using template/dev-4.14.0.opam" && cp dependencies/template/dev-4.14.0.opam "$dev_opam" ;;
    *)
        echo "Using template/dev.opam" && cp dependencies/template/dev.opam "$dev_opam" ;;
esac

# Conditionally install runtime_events_tools for olly (pausetimes)
if [[ $config_switch_name =~ 5.* ]]; then
    echo "Enabling pausetimes for OCaml >= 5";
    packages+=" runtime_events_tools"
else
    echo "Pausetimes unavailable for OCaml < 5"
fi

opam repo add alpha git+https://github.com/kit-ty-kate/opam-alpha-repository.git --on-switch="$config_switch_name" --rank 2
opam exec --switch "$config_switch_name" -- opam update
opam install --switch="$config_switch_name" --yes "lru" "psq"
opam exec --switch "$config_switch_name" -- opam list
if [ ! "$use_sys_dune_hack" ]; then
    opam install --switch="$config_switch_name" --yes "dune.$sandmark_dune_version" "dune-configurator.$sandmark_dune_version" "dune-private-libs.$sandmark_dune_version"; ex=$?;
    if [ $ex -ne 0 ] && [ ! "$continue_on_opam_install_error" ]; then
        exit 1
    fi
fi;
opam update --switch="$config_switch_name";
for i in $packages; do
    sed -i "/^]/i \ \ \"$i\"" "$dev_opam";
done;

declare -A override=( [ocaml-config]='"ocaml-config" {= "1"}');

add_to_override () {
    pkg_name=$(cut -d '.' -f 1 <<< "$1");
    pkg_version=$(cut -d '.' -f 2- <<< "$1");
    override["$pkg_name"]="\"$pkg_name\" {= \"$pkg_version\" }"
}

if [ -z "$sandmark_override_packages" ]; then
    for pkg in $(jq -r '.package_overrides | .[]?' ocaml-versions/"$config_switch_name".json); do
        add_to_override "$pkg"
    done;
else
    for p in $sandmark_override_packages; do
        add_to_override "$p"
    done;
fi;
for key in "${!override[@]}"; do
    sed -i "/\"$key\"/s/.*/  ${override[$key]}/" "$dev_opam";
done;

remove_from_dev_opam () {
    if [ -n "${override[$1]}" ]; then
        sed -i "/\"$1\"/s/.*/ /" "$dev_opam";
    fi
}

if [ -z "$sandmark_remove_packages" ]; then
    for pkg in $(jq -r '.package_remove | .[]?' ocaml-versions/"$config_switch_name".json); do
        remove_from_dev_opam "$pkg"
    done;
else
    for pkg in $sandmark_remove_packages; do
        remove_from_dev_opam "$pkg"
    done;
fi;
sed -i '/^\s*$/d' "$dev_opam";
opam install "$dev_opam" --switch="$config_switch_name" --yes --deps-only;
opam list --switch="$config_switch_name";
