(executable (name test_wsqueue) (modules test_wsqueue) (libraries lockfree))

(rule
            (targets test_wsqueue.1.bench)
            (deps (:prog test_wsqueue.exe))
            (action (run orun -o %{targets} -- %{prog} 1)))
(rule
            (targets test_wsqueue.2.bench)
            (deps (:prog test_wsqueue.exe))
            (action (run orun -o %{targets} -- %{prog} 2)))
(rule
            (targets test_wsqueue.3.bench)
            (deps (:prog test_wsqueue.exe))
            (action (run orun -o %{targets} -- %{prog} 3)))

(alias (name multibench_parallel) (deps test_wsqueue.2.bench test_wsqueue.3.bench))
(alias (name multibench_serial) (deps test_wsqueue.1.bench))
