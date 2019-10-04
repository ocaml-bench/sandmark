(executable (name test_wsqueue) (modules test_wsqueue) (libraries lockfree))

(alias (name buildmultibench) (deps test_wsqueue.exe))
