#!/bin/bash

SANDMARK_NIGHTLY_DEFAULT_DIR="$HOME/production/sandmark_nightly_workspace"
CUSTOM_FILE="https://raw.githubusercontent.com/ocaml-bench/sandmark-nightly-config/main/config/custom_turing.json"
MACHINE="Turing"
HERE=$(dirname $0)

SANDMARK_NIGHTLY_DEFAULT_DIR=${SANDMARK_NIGHTLY_DEFAULT_DIR} \
                            MACHINE=${MACHINE} \
                            CUSTOM_FILE=${CUSTOM_FILE} \
                            bash "${HERE}/nightly.sh" "$@"
