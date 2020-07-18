(executable
    (name capi)
    (modules capi)
    (libraries ocamlcapi))

(library
    (name ocamlcapi)
    (modules ocamlcapi)
    (foreign_stubs (language c) (names ocamlcapi)))

(alias (name buildbench) (deps capi.exe))
