(executable (name big_array_bench) (modes native byte) (modules big_array_bench) (libraries bigarray))

(alias (name buildbench) (deps big_array_bench.exe))

(alias (name bytebench) (deps big_array_bench.bc))
