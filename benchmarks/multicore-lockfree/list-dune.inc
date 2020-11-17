(executable
	(name test_list)
	(modules test_list)
	(libraries lockfree))

(executable
	(name test_list_multicore)
	(modules test_list_multicore)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_list.exe test_wsqueue_multicore.exe))
