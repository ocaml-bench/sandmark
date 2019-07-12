(executable (name str_bench) (modules str_bench) (libraries str))

(rule
         (targets str_bench.str_regexp.1000000.bench)
          (deps (:prog str_bench.exe))
           (action (run orun -o %{targets} -- %{prog} str_regexp 1000000)))
(rule
         (targets str_bench.str_string_match.1000000.bench)
          (deps (:prog str_bench.exe))
           (action (run orun -o %{targets} -- %{prog} str_string_match 1000000)))
(rule
         (targets str_bench.str_search_forward.1000000.bench)
          (deps (:prog str_bench.exe))
           (action (run orun -o %{targets} -- %{prog} str_search_forward 1000000)))
(rule
         (targets str_bench.str_string_partial_match.1000000.bench)
          (deps (:prog str_bench.exe))
           (action (run orun -o %{targets} -- %{prog} str_string_partial_match 1000000)))
(rule
         (targets str_bench.str_global_replace.1000000.bench)
          (deps (:prog str_bench.exe))
           (action (run orun -o %{targets} -- %{prog} str_global_replace 1000000)))
(rule
         (targets str_bench.str_split.1000000.bench)
          (deps (:prog str_bench.exe))
           (action (run orun -o %{targets} -- %{prog} str_split 1000000)))

(alias (name bench) (deps str_bench.str_regexp.1000000.bench str_bench.str_string_match.1000000.bench str_bench.str_search_forward.1000000.bench str_bench.str_string_partial_match.1000000.bench str_bench.str_global_replace.1000000.bench str_bench.str_split.1000000.bench))
