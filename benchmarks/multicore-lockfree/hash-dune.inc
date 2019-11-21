(executable
	(name test_hash)
	(modules test_hash)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_hash.exe))
