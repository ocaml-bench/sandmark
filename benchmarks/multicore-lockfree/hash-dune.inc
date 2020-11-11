(executable
	(name test_hash)
	(modules test_hash)
	(libraries lockfree))

(executable
	(name test_hash_multicore)
	(modules test_hash_multicore)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_hash.exe test_hash_multicore.exe))
