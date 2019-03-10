(executable (name lazylist) (modules lazylist))

(rule
        (targets lazylist.500000.100.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 500000 100)))
(rule
        (targets lazylist.50000.1000.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 50000 1000)))
(rule
        (targets lazylist.5000.10000.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 5000 10000)))
(rule
        (targets lazylist.500.100000.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 500 100000)))

(alias (name bench) (deps lazylist.500000.100.bench lazylist.50000.1000.bench lazylist.5000.10000.bench lazylist.500.100000.bench))
