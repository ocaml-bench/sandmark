(executable (name set_bench) (modules set_bench))

(rule
         (targets set_bench.set_fold.1000000.bench)
          (deps (:prog set_bench.exe))
           (action (run orun -o %{targets} -- %{prog} set_fold 1000000)))
(rule
         (targets set_bench.set_add_rem.20000000.bench)
          (deps (:prog set_bench.exe))
           (action (run orun -o %{targets} -- %{prog} set_add_rem 20000000)))
(rule
         (targets set_bench.set_mem.50000000.bench)
          (deps (:prog set_bench.exe))
           (action (run orun -o %{targets} -- %{prog} set_mem 50000000)))

(alias (name bench) (deps set_bench.set_fold.1000000.bench set_bench.set_add_rem.20000000.bench set_bench.set_mem.50000000.bench))
