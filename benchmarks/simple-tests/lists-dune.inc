(executable (name lists) (modules lists))

(rule
         (targets lists.int.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int 1)))
(rule
         (targets lists.int.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int 10000)))
(rule
         (targets lists.int.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int 100000)))
(rule
         (targets lists.float.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float 1)))
(rule
         (targets lists.float.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float 10000)))
(rule
         (targets lists.float.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float 100000)))
(rule
         (targets lists.int-tuple.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-tuple 1)))
(rule
         (targets lists.int-tuple.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-tuple 10000)))
(rule
         (targets lists.int-tuple.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-tuple 100000)))
(rule
         (targets lists.float-tuple.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float-tuple 1)))
(rule
         (targets lists.float-tuple.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float-tuple 10000)))
(rule
         (targets lists.float-tuple.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float-tuple 100000)))
(rule
         (targets lists.string.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} string 1)))
(rule
         (targets lists.string.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} string 10000)))
(rule
         (targets lists.string.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} string 100000)))
(rule
         (targets lists.record.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} record 1)))
(rule
         (targets lists.record.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} record 10000)))
(rule
         (targets lists.record.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} record 100000)))
(rule
         (targets lists.float-array.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float-array 1)))
(rule
         (targets lists.float-array.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float-array 10000)))
(rule
         (targets lists.float-array.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} float-array 100000)))
(rule
         (targets lists.int-array.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-array 1)))
(rule
         (targets lists.int-array.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-array 10000)))
(rule
         (targets lists.int-array.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-array 100000)))
(rule
         (targets lists.int-option-array.100.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-option-array 1)))
(rule
         (targets lists.int-option-array.10000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-option-array 10000)))
(rule
         (targets lists.int-option-array.1000000.bench)
          (deps (:prog lists.exe))
           (action (run orun -o %{targets} -- %{prog} int-option-array 100000)))

(alias (name bench) (deps lists.int.100.bench lists.int.10000.bench lists.int.1000000.bench lists.float.100.bench lists.float.10000.bench lists.float.1000000.bench lists.int-tuple.100.bench lists.int-tuple.10000.bench lists.int-tuple.1000000.bench lists.float-tuple.100.bench lists.float-tuple.10000.bench lists.float-tuple.1000000.bench lists.string.100.bench lists.string.10000.bench lists.string.1000000.bench lists.record.100.bench lists.record.10000.bench lists.record.1000000.bench lists.float-array.100.bench lists.float-array.10000.bench lists.float-array.1000000.bench lists.int-array.100.bench lists.int-array.10000.bench lists.int-array.1000000.bench lists.int-option-array.100.bench lists.int-option-array.10000.bench lists.int-option-array.1000000.bench))
