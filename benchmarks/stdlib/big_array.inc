(executable (name big_array_bench) (modules big_array_bench) (libraries bigarray))

(rule
         (targets big_array_bench.big_array_int_rev.1024.50000.bench)
          (deps (:prog big_array_bench.exe))
           (action (run orun -o %{targets} -- %{prog} big_array_int_rev 1024 50000)))

(alias (name bench) (deps big_array_bench.big_array_int_rev.1024.50000.bench ))
