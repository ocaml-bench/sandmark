#!/usr/bin/env bash

SCALE=$1

gen () { ./_build/default/gen.exe -scale $SCALE edges.data; }

kernel1 () { ./_build/default/kernel1_run.exe edges.data -o sparse.data; }

getSamples () { ./_build/default/sampleSearchKeys.exe sparse.data -o samples.data; }

gen && kernel1 && getSamples 


