(executable (name string_bench) (modes native byte) (modules string_bench))

(alias (name buildbench) (deps string_bench.exe))

(alias (name bytebench) (deps string_bench.bc))