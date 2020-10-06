(library
	(name ctrie)
	(modules ctrie)
	(libraries base))

(executable
	(name test_ctrie)
	(modules test_ctrie)
  (libraries ctrie))

(executable
	(name test_ctrie_sequential)
	(modules test_ctrie_sequential)
  (libraries ctrie))

(alias (name multibench_parallel) (deps test_ctrie.exe test_ctrie_sequential.exe))
