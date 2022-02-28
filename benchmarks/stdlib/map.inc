(executable (name map_bench) (modes native byte) (modules map_bench))

(alias (name bytebench) (deps map_bench.bc))
