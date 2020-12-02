(executable
	(name test_bag)
	(modules test_bag)
	(libraries lockfree))

(executable
	(name test_bag_multicore)
	(modules test_bag_multicore)
	(libraries lockfree))

(alias (name multibench_parallel) (deps test_bag.exe test_bag_multicore.exe))