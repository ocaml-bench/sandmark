#!/bin/sh
# Using to automate the running of kernel-2 and kernel-3 inclusing kronecker and kernel1 as included modules.

kronecker="kronecker"
hashmapKernel="kernel1"
bfs="kernel2"
shortestPath="kernel3"
ocamlExt=".ml"

ocamlopt -c $kronecker$ocamlExt
ocamlopt -c $hashmapKernel$ocamlExt 
ocamlopt -c $bfs$ocamlExt
ocamlopt -c $shortestPath$ocamlExt