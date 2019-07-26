(executable (name lazylist) (modules lazylist))

(rule
        (targets lazylist.1000000.10.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 1000000 10)))
(rule
        (targets lazylist.100000.100.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 100000 100)))
(rule
        (targets lazylist.10000.1000.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 10000 1000)))
(rule
        (targets lazylist.1000.10000.bench)
        (deps (:prog lazylist.exe))
        (action (run orun -o %{targets} -- %{prog} 1000 10000)))

(alias (name bench) (deps lazylist.1000000.10.bench lazylist.100000.100.bench lazylist.10000.1000.bench lazylist.1000.10000.bench))
