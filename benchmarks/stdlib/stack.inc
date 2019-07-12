(executable (name stack_bench) (modules stack_bench))

(rule
         (targets stack_bench.stack_fold.1000000.bench)
          (deps (:prog stack_bench.exe))
           (action (run orun -o %{targets} -- %{prog} stack_fold 1000000)))
(rule
         (targets stack_bench.stack_push_pop.1000000.bench)
          (deps (:prog stack_bench.exe))
           (action (run orun -o %{targets} -- %{prog} stack_push_pop 1000000)))

(alias (name bench) (deps stack_bench.stack_fold.1000000.bench stack_bench.stack_push_pop.1000000.bench))
