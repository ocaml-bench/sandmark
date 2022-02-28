(executable (name stack_bench) (modes native byte) (modules stack_bench))

(alias (name buildbench) (deps stack_bench.exe))

(alias (name bytebench) (deps stack_bench.bc))