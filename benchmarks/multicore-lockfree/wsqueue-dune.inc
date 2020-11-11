(executable
	(name test_wsqueue)
	(modules test_wsqueue)
	(libraries lockfree))

(executable
	(name test_wsqueue_parallel)
	(modules test_wsqueue_parallel)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_wsqueue.exe test_wsqueue_parallel.exe))
