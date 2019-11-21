(executable
	(name test_wsqueue)
	(modules test_wsqueue)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_wsqueue.exe))
