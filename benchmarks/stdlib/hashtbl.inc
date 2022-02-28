(executable (name hashtbl_bench) (modes native byte) (modules hashtbl_bench))

(alias (name buildbench) (deps hashtbl_bench.exe))

(alias (name bytebench) (deps hashtbl_bench.bc))
