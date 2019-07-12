(executable (name bytes_bench) (modules bytes_bench))

(rule
         (targets bytes_bench.bytes_get.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_get 1000000)))
(rule
         (targets bytes_bench.bytes_sub.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_sub 1000000)))
(rule
         (targets bytes_bench.bytes_blit.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_blit 1000000)))
(rule
         (targets bytes_bench.bytes_concat.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_concat 1000000)))
(rule
         (targets bytes_bench.bytes_iter.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_iter 1000000)))
(rule
         (targets bytes_bench.bytes_map.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_map 1000000)))
(rule
         (targets bytes_bench.bytes_trim.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_trim 1000000)))
(rule
         (targets bytes_bench.bytes_index.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_index 1000000)))
(rule
         (targets bytes_bench.bytes_contains.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_contains 1000000)))
(rule
         (targets bytes_bench.bytes_uppercase_ascii.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_uppercase_ascii 1000000)))
(rule
         (targets bytes_bench.bytes_set.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_set 1000000)))
(rule
         (targets bytes_bench.bytes_cat.1000000.bench)
          (deps (:prog bytes_bench.exe))
           (action (run orun -o %{targets} -- %{prog} bytes_cat 1000000)))

(alias (name bench) (deps bytes_bench.bytes_get.1000000.bench bytes_bench.bytes_sub.1000000.bench bytes_bench.bytes_blit.1000000.bench bytes_bench.bytes_concat.1000000.bench bytes_bench.bytes_iter.1000000.bench bytes_bench.bytes_map.1000000.bench bytes_bench.bytes_trim.1000000.bench bytes_bench.bytes_index.1000000.bench bytes_bench.bytes_contains.1000000.bench bytes_bench.bytes_uppercase_ascii.1000000.bench bytes_bench.bytes_set.1000000.bench bytes_bench.bytes_cat.1000000.bench))
