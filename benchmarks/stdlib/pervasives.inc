(executable (name pervasives_bench) (modes native byte) (modules pervasives_bench))

(alias (name buildbench) (deps pervasives_bench.exe))

(alias (name bytebench) (deps pervasives_bench.bc))