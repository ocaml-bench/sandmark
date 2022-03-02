(executable (name array_bench) (modes native byte) (modules array_bench))

(alias (name buildbench) (deps array_bench.exe))

(alias (name bytebench) (deps array_bench.bc))
