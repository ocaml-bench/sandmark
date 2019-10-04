(executable (name hashtbl_bench) (modules hashtbl_bench))

(alias (name buildbench) (deps hashtbl_bench.exe))
