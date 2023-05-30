#!/bin/bash

# TOKEN required to commit to sandmark-nightly repository
TOKEN=$1

# The default Sandmark nightly directory
SANDMARK_NIGHTLY_DIR=${SANDMARK_NIGHTLY_DIR:-"$HOME/production/sandmark_nightly_workspace"}

# Check if sandmark-nightly directory exists
function check_sandmark_subdir {
    if [ ! -d $1/sandmark-nightly ]; then
        git clone -b testing https://"$TOKEN"@github.com/ocaml-bench/sandmark-nightly.git "$1"/sandmark-nightly
    fi;
}

# Sandmark nightly directory
if [ ! -d "$SANDMARK_NIGHTLY_DIR" ]; then
    mkdir "$SANDMARK_NIGHTLY_DIR"
fi;

# Check Sandmark nightly sub-directories
check_sandmark_subdir "$SANDMARK_NIGHTLY_DIR"

# OPAM context
eval $(opam env)

# Run!
SANDMARK_NIGHTLY_DIR=${SANDMARK_NIGHTLY_DIR} CUSTOM_FILE="https://raw.githubusercontent.com/ocaml-bench/sandmark-nightly-config/main/config/custom_turing.json" flock -w 7200 /tmp/sandmark.lock bash /home/sandmark/production/run_all_custom.sh | ts '[%Y-%m-%d %H:%M:%S]'

# Push to sandmark-nightly
cd "$SANDMARK_NIGHTLY_DIR"/sandmark-nightly/
git pull origin testing
git add .
git commit -m "Automated commit (Turing)"
git push origin testing
