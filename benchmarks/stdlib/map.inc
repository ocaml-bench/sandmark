(executable (name map_bench) (modules map_bench))

(rule
         (targets map_bench.map_iter.10.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_iter 10)))
(rule
         (targets map_bench.map_add.1000000.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_add 1000000)))
(rule
         (targets map_bench.map_add_duplicate.1000000.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_add_duplicate 1000000)))
(rule
         (targets map_bench.map_remove.1000000.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_remove 1000000)))
(rule
         (targets map_bench.map_fold.10.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_fold 10)))
(rule
         (targets map_bench.map_for_all.10.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_for_all 10)))
(rule
         (targets map_bench.map_find.1000000.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_find 1000000)))
(rule
         (targets map_bench.map_map.10.bench)
          (deps (:prog map_bench.exe))
           (action (run orun -o %{targets} -- %{prog} map_map 10)))

(alias (name bench) (deps map_bench.map_iter.10.bench map_bench.map_add.1000000.bench map_bench.map_add_duplicate.1000000.bench map_bench.map_remove.1000000.bench map_bench.map_fold.10.bench map_bench.map_for_all.10.bench map_bench.map_find.1000000.bench map_bench.map_map.10.bench))
