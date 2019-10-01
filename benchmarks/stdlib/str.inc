(executable (name str_bench) (modules str_bench) (libraries str))

(alias (name buildbench) (deps str_bench.exe))