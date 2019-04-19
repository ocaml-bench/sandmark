(executable (name test_hash) (modules test_hash) (libraries lockfree))

(rule
            (targets test_hash.1.25.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 1 25)))
(rule
            (targets test_hash.2.25.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 2 25)))
(rule
            (targets test_hash.3.25.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 3 25)))
(rule
            (targets test_hash.1.50.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 1 50)))
(rule
            (targets test_hash.2.50.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 2 50)))
(rule
            (targets test_hash.3.50.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 3 50)))
(rule
            (targets test_hash.1.75.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 1 75)))
(rule
            (targets test_hash.2.75.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 2 75)))
(rule
            (targets test_hash.3.75.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 3 75)))
(rule
            (targets test_hash.1.99.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 1 99)))
(rule
            (targets test_hash.2.99.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 2 99)))
(rule
            (targets test_hash.3.99.bench)
            (deps (:prog test_hash.exe))
            (action (run orun -o %{targets} -- %{prog} 3 99)))

(alias (name bench) (deps test_hash.1.25.bench test_hash.2.25.bench test_hash.3.25.bench test_hash.1.50.bench test_hash.2.50.bench test_hash.3.50.bench test_hash.1.75.bench test_hash.2.75.bench test_hash.3.75.bench test_hash.1.99.bench test_hash.2.99.bench test_hash.3.99.bench))
