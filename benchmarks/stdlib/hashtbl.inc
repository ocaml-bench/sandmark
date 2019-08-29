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
         (targets hashtbl_bench.caml_hash_int.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} caml_hash_int 10)))
(rule
         (targets hashtbl_bench.caml_hash_tuple.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} caml_hash_tuple 10)))           
(rule
         (targets hashtbl_bench.int_replace2.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_replace2 10)))
(rule
         (targets hashtbl_bench.int_find2.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} int_find2 10)))
(rule
         (targets hashtbl_bench.hashtbl_iter.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_iter 10)))
(rule
         (targets hashtbl_bench.hashtbl_fold.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_fold 10)))
(rule
         (targets hashtbl_bench.hashtbl_add_resizing.1000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_add_resizing 1000000)))
(rule
         (targets hashtbl_bench.hashtbl_add_sized.1000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_add_sized 1000000)))
(rule
         (targets hashtbl_bench.hashtbl_add_duplicate.1000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_add_duplicate 1000000)))
(rule
         (targets hashtbl_bench.hashtbl_remove.1000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_remove 1000000)))
(rule
         (targets hashtbl_bench.hashtbl_find.1000000.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_find 1000000)))
(rule
         (targets hashtbl_bench.hashtbl_filter_map.10.bench)
          (deps (:prog hashtbl_bench.exe))
           (action (run orun -o %{targets} -- %{prog} hashtbl_filter_map 10)))

(alias (name bench) (deps hashtbl_bench.int_replace1.10.bench hashtbl_bench.int_find1.10.bench hashtbl_bench.caml_hash_tuple.10.bench hashtbl_bench.caml_hash_int.10.bench hashtbl_bench.int_replace2.10.bench hashtbl_bench.int_find2.10.bench hashtbl_bench.hashtbl_iter.10.bench hashtbl_bench.hashtbl_fold.10.bench hashtbl_bench.hashtbl_add_resizing.1000000.bench hashtbl_bench.hashtbl_add_sized.1000000.bench hashtbl_bench.hashtbl_add_duplicate.1000000.bench hashtbl_bench.hashtbl_remove.1000000.bench hashtbl_bench.hashtbl_find.1000000.bench hashtbl_bench.hashtbl_filter_map.10.bench))