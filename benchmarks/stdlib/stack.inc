(executable (name stack_bench) (modules stack_bench))

(alias (name buildbench) (deps stack_bench.exe))