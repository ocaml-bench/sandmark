(executable (name bytes_bench) (modules bytes_bench))

(alias (name buildbench) (deps bytes_bench.exe))
