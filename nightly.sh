#!/bin/bash

set -u

# TOKEN required to commit to sandmark-nightly repository
TOKEN=$1

# The default Sandmark nightly directory
SANDMARK_NIGHTLY_DIR=${SANDMARK_NIGHTLY_DIR:-${SANDMARK_NIGHTLY_DEFAULT_DIR}}

# Check if sandmark-nightly directory exists
function check_sandmark_subdir {
    if [ ! -d $1/sandmark-nightly ]; then
        git clone -b testing https://$TOKEN@github.com/ocaml-bench/sandmark-nightly.git $1/sandmark-nightly
    fi;
}

# Sandmark nightly directory
if [ ! -d $SANDMARK_NIGHTLY_DIR ]; then
    mkdir $SANDMARK_NIGHTLY_DIR
fi;

# Check Sandmark nightly sub-directories
check_sandmark_subdir $SANDMARK_NIGHTLY_DIR

# OPAM context
eval $(opam env)

# Run!
SANDMARK_NIGHTLY_DIR=${SANDMARK_NIGHTLY_DIR} CUSTOM_FILE=${CUSTOM_FILE} bash /home/sandmark/production/run_all_custom.sh

# Push to sandmark-nightly
cd $SANDMARK_NIGHTLY_DIR/sandmark-nightly/
git pull origin testing
git add .
git commit -m "Automated commit (${MACHINE})"
git push origin testing
