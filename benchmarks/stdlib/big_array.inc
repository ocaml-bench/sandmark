(executable (name big_array_bench) (modules big_array_bench) (libraries bigarray))

(alias (name buildbench) (deps big_array_bench.exe))
