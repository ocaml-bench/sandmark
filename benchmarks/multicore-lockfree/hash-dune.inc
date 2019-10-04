(executable (name test_hash) (modules test_hash) (libraries lockfree))

(alias (name buildmultibench) (deps test_hash.exe))
