(executable (name stress) (modules stress))

(rule
         (targets stress.1.10.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 1 10)))
(rule
         (targets stress.10000.10.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 10000 10)))
(rule
         (targets stress.100000.10.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 100000 10)))
(rule
         (targets stress.1.25.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 1 25)))
(rule
         (targets stress.10000.25.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 10000 25)))
(rule
         (targets stress.100000.25.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 100000 25)))
(rule
         (targets stress.1.50.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 1 50)))
(rule
         (targets stress.10000.50.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 10000 50)))
(rule
         (targets stress.100000.50.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 100000 50)))
(rule
         (targets stress.1.75.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 1 75)))
(rule
         (targets stress.10000.75.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 10000 75)))
(rule
         (targets stress.100000.75.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 100000 75)))
(rule
         (targets stress.1.100.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 1 100)))
(rule
         (targets stress.10000.100.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 10000 100)))
(rule
         (targets stress.100000.100.bench)
          (deps (:prog stress.exe))
           (action (run orun -o %{targets} -- %{prog} 100000 100)))

(alias (name bench) (deps stress.1.10.bench stress.10000.10.bench stress.100000.10.bench stress.1.25.bench stress.10000.25.bench stress.100000.25.bench stress.1.50.bench stress.10000.50.bench stress.100000.50.bench stress.1.75.bench stress.10000.75.bench stress.100000.75.bench stress.1.100.bench stress.10000.100.bench stress.100000.100.bench))
