(executable (name finalise) (modules finalise))

(rule
         (targets finalise.10.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 10)))
(rule
         (targets finalise.20.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 20)))
(rule
         (targets finalise.30.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 30)))
(rule
         (targets finalise.40.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 40)))
(rule
         (targets finalise.50.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 50)))
(rule
         (targets finalise.60.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 60)))
(rule
         (targets finalise.70.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 70)))
(rule
         (targets finalise.80.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 80)))
(rule
         (targets finalise.90.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 90)))
(rule
         (targets finalise.100.bench)
          (deps (:prog finalise.exe))
           (action (run orun -o %{targets} -- %{prog} 100)))

(alias (name bench) (deps finalise.10.bench finalise.20.bench finalise.30.bench finalise.40.bench finalise.50.bench finalise.60.bench finalise.70.bench finalise.80.bench finalise.90.bench finalise.100.bench))
