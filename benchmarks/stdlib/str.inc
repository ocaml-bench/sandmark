(executable (name str_bench) (modes native byte) (modules str_bench) (libraries str))

(alias (name buildbench) (deps str_bench.exe))

(alias (name bytebench) (deps str_bench.bc))