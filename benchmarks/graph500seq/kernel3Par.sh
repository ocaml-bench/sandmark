#!/usr/bin/env bash

NDOMAINS=$1

./_build/default/kernel3_run_multicore.exe sparse.data samples.data -ndomains $NDOMAINS
