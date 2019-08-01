(executable (name string_bench) (modules string_bench))

(rule
         (targets string_bench.string_get.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_get 1000000)))
(rule
         (targets string_bench.string_sub.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_sub 1000000)))
(rule
         (targets string_bench.string_blit.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_blit 1000000)))
(rule
         (targets string_bench.string_concat.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_concat 1000000)))
(rule
         (targets string_bench.string_iter.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_iter 1000000)))
(rule
         (targets string_bench.string_map.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_map 1000000)))
(rule
         (targets string_bench.string_trim.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_trim 1000000)))
(rule
         (targets string_bench.string_index.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_index 1000000)))
(rule
         (targets string_bench.string_contains.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_contains 1000000)))
(rule
         (targets string_bench.string_uppercase_ascii.1000000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_uppercase_ascii 1000000)))

(rule
         (targets string_bench.string_split_on_char.250000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_split_on_char 250000)))

(rule
         (targets string_bench.string_compare.10000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_compare 10000)))

(rule
         (targets string_bench.string_equal.10000.bench)
          (deps (:prog string_bench.exe))
           (action (run orun -o %{targets} -- %{prog} string_equal 10000)))


(alias (name bench) (deps string_bench.string_get.1000000.bench string_bench.string_sub.1000000.bench string_bench.string_blit.1000000.bench string_bench.string_concat.1000000.bench string_bench.string_iter.1000000.bench string_bench.string_map.1000000.bench string_bench.string_trim.1000000.bench string_bench.string_index.1000000.bench string_bench.string_contains.1000000.bench string_bench.string_uppercase_ascii.1000000.bench string_bench.string_split_on_char.250000.bench string_bench.string_compare.10000.bench string_bench.string_equal.10000.bench))
