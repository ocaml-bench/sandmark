(executable (name pervasives_bench) (modules pervasives_bench))

(rule
             (targets pervasives_bench.pervasives_equal_lists.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_equal_lists 100000000)))
(rule
             (targets pervasives_bench.pervasives_compare_lists.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_compare_lists 100000000)))
(rule
             (targets pervasives_bench.pervasives_equal_ints.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_equal_ints 100000000)))
(rule
             (targets pervasives_bench.pervasives_compare_ints.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_compare_ints 100000000)))
(rule
             (targets pervasives_bench.pervasives_equal_floats.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_equal_floats 100000000)))
(rule
             (targets pervasives_bench.pervasives_compare_floats.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_compare_floats 100000000)))
(rule
             (targets pervasives_bench.pervasives_equal_strings.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_equal_strings 100000000)))
(rule
             (targets pervasives_bench.pervasives_compare_strings.100000000.bench)
              (deps (:prog pervasives_bench.exe))
               (action (run orun -o %{targets} -- %{prog} pervasives_compare_strings 100000000)))

(alias (name bench) (deps pervasives_bench.pervasives_equal_lists.100000000.bench pervasives_bench.pervasives_compare_lists.100000000.bench pervasives_bench.pervasives_equal_ints.100000000.bench pervasives_bench.pervasives_compare_ints.100000000.bench pervasives_bench.pervasives_equal_floats.100000000.bench pervasives_bench.pervasives_compare_floats.100000000.bench pervasives_bench.pervasives_equal_strings.20000000.bench pervasives_bench.pervasives_compare_strings.20000000.bench))
