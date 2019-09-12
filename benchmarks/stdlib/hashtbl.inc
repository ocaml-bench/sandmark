(executable (name hashtbl_bench) (modules hashtbl_bench))

(rule
         (targets hashtbl_bench.int_replace1.10000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_replace1 10000)))
(rule
         (targets hashtbl_bench.int_find1.20000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_find1 20000)))
(rule
         (targets hashtbl_bench.caml_hash_int.200000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} caml_hash_int 200000)))
(rule
         (targets hashtbl_bench.caml_hash_tuple.100000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} caml_hash_tuple 100000)))           
(rule
         (targets hashtbl_bench.int_replace2.100000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_replace2 100000)))
(rule
         (targets hashtbl_bench.int_find2.300000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_find2 300000)))
(rule
         (targets hashtbl_bench.hashtbl_iter.200000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_iter 200000)))
(rule
         (targets hashtbl_bench.hashtbl_fold.200000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_fold 200000)))
(rule
         (targets hashtbl_bench.hashtbl_add_resizing.4000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_add_resizing 4000000)))
(rule
         (targets hashtbl_bench.hashtbl_add_sized.6000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_add_sized 6000000)))
(rule
         (targets hashtbl_bench.hashtbl_add_duplicate.2000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_add_duplicate 2000000)))
(rule
         (targets hashtbl_bench.hashtbl_remove.4000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_remove 4000000)))
(rule
         (targets hashtbl_bench.hashtbl_find.7000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_find 7000000)))
(rule
         (targets hashtbl_bench.hashtbl_filter_map.100000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_filter_map 100000)))

(alias (name bench) (deps hashtbl_bench.int_replace1.10000.bench hashtbl_bench.int_find1.20000.bench hashtbl_bench.caml_hash_tuple.100000.bench hashtbl_bench.caml_hash_int.200000.bench hashtbl_bench.int_replace2.100000.bench hashtbl_bench.int_find2.300000.bench hashtbl_bench.hashtbl_iter.200000.bench hashtbl_bench.hashtbl_fold.200000.bench hashtbl_bench.hashtbl_add_resizing.4000000.bench hashtbl_bench.hashtbl_add_sized.6000000.bench hashtbl_bench.hashtbl_add_duplicate.2000000.bench hashtbl_bench.hashtbl_remove.4000000.bench hashtbl_bench.hashtbl_find.7000000.bench hashtbl_bench.hashtbl_filter_map.100000.bench))
