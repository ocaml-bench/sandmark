(executable (name bytes_bench) (modes native byte) (modules bytes_bench))

(alias (name buildbench) (deps bytes_bench.exe))

(alias (name bytebench) (deps bytes_bench.bc))
