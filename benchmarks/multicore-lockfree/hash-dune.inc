(executable
	(name test_hash)
	(modules test_hash)
	(libraries lockfree))

(executable
	(name test_hash_parallel)
	(modules test_hash_parallel)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_hash.exe test_hash_parallel.exe))
