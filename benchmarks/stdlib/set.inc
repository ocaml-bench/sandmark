(executable (name set_bench) (modes native byte) (modules set_bench))

(alias (name buildbench) (deps set_bench.exe))

(alias (name bytebench) (deps set_bench.bc))