(executable
    (name capi)
    (modules capi)
    (libraries ocamlcapi))

(library
    (name ocamlcapi)
    (modules ocamlcapi)
    (c_names ocamlcapi))

(alias (name buildbench) (deps capi.exe))