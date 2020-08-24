#!/bin/sh
# Using to automate the running of kernel-2 and kernel-3 inclusing kronecker and kernel1 as included modules.

module=".cmx"
kronecker="kronecker"$module
hashmapKernel="kernel1"$module
bfs="kernel2"$module
shortestPath="kernel3"$module
code="c"

ocamlopt -o $code $kronecker $hashmapKernel $bfs
./$code $1 $2
ocamlopt -o $code $kronecker $hashmapKernel $shortestPath
./$code $1 $2 $3