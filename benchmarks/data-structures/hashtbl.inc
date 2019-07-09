(executable (name hashtbl_bench) (modules hashtbl_bench))

(rule
         (targets hashtbl_bench.int_replace1.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_replace1 10)))
(rule
         (targets hashtbl_bench.int_find1.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_find1 10)))
(rule
         (targets hashtbl_bench.caml_hash.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} caml_hash 10)))
(rule
         (targets hashtbl_bench.int_replace2.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_replace2 10)))
(rule
         (targets hashtbl_bench.int_find2.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_find2 10)))

(alias (name bench) (deps hashtbl_bench.int_replace1.10.bench hashtbl_bench.int_find1.10.bench hashtbl_bench.caml_hash.10.bench hashtbl_bench.int_replace2.10.bench hashtbl_bench.int_find2.10.bench))
