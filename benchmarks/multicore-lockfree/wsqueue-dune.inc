(executable
	(name test_wsqueue)
	(modules test_wsqueue)
	(libraries lockfree unix))

(executable
	(name test_wsqueue_multicore)
	(modules test_wsqueue_multicore)
	(libraries lockfree unix))

(alias (name multibench_parallel) (deps test_wsqueue.exe test_wsqueue_multicore.exe))
