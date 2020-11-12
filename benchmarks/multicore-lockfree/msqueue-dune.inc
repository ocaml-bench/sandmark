(executable
	(name test_msqueue)
	(modules test_msqueue)
	(libraries lockfree))

(executable
	(name test_msqueue_multicore)
	(modules test_msqueue_multicore)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_msqueue.exe test_msqueue_multicore.exe))
