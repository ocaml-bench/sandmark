(executable (name weakretain) (modules weakretain))

(rule
            (targets weakretain.25.1000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 25 1000)))
(rule
            (targets weakretain.25.10000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 25 10000)))
(rule
            (targets weakretain.25.100000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 25 100000)))
(rule
            (targets weakretain.25.1000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 25 1000000)))
(rule
            (targets weakretain.25.10000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 25 10000000)))
(rule
            (targets weakretain.50.1000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 50 1000)))
(rule
            (targets weakretain.50.10000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 50 10000)))
(rule
            (targets weakretain.50.100000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 50 100000)))
(rule
            (targets weakretain.50.1000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 50 1000000)))
(rule
            (targets weakretain.50.10000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 50 10000000)))
(rule
            (targets weakretain.75.1000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 75 1000)))
(rule
            (targets weakretain.75.10000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 75 10000)))
(rule
            (targets weakretain.75.100000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 75 100000)))
(rule
            (targets weakretain.75.1000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 75 1000000)))
(rule
            (targets weakretain.75.10000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 75 10000000)))
(rule
            (targets weakretain.100.1000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 100 1000)))
(rule
            (targets weakretain.100.10000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 100 10000)))
(rule
            (targets weakretain.100.100000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 100 100000)))
(rule
            (targets weakretain.100.1000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 100 1000000)))
(rule
            (targets weakretain.100.10000000.bench)
            (deps (:prog weakretain.exe))
            (action (run orun -o %{targets} -- %{prog} 100 10000000)))

(alias (name bench) (deps weakretain.25.1000.bench weakretain.25.10000.bench weakretain.25.100000.bench weakretain.25.1000000.bench weakretain.25.10000000.bench weakretain.50.1000.bench weakretain.50.10000.bench weakretain.50.100000.bench weakretain.50.1000000.bench weakretain.50.10000000.bench weakretain.75.1000.bench weakretain.75.10000.bench weakretain.75.100000.bench weakretain.75.1000000.bench weakretain.75.10000000.bench weakretain.100.1000.bench weakretain.100.10000.bench weakretain.100.100000.bench weakretain.100.1000000.bench weakretain.100.10000000.bench))
