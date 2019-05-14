(executable
    (name capi)
    (modules capi)
    (libraries ocamlcapi))

(library
    (name ocamlcapi)
    (modules ocamlcapi)
    (c_names ocamlcapi))

(rule
         (targets test_no_args_alloc.bench)
          (deps (:prog capi.exe))
           (action (run orun -o %{targets} -- %{prog} test_no_args_alloc 200_000_000)))

(rule
         (targets test_no_args_noalloc.bench)
          (deps (:prog capi.exe))
           (action (run orun -o %{targets} -- %{prog} test_no_args_noalloc 200_000_000)))

(rule
         (targets test_few_args_alloc.bench)
          (deps (:prog capi.exe))
           (action (run orun -o %{targets} -- %{prog} test_few_args_alloc 200_000_000)))

(rule
         (targets test_few_args_noalloc.bench)
          (deps (:prog capi.exe))
           (action (run orun -o %{targets} -- %{prog} test_few_args_noalloc 200_000_000)))

(rule
         (targets test_many_args_alloc.bench)
          (deps (:prog capi.exe))
           (action (run orun -o %{targets} -- %{prog} test_many_args_alloc 200_000_000)))

(rule
         (targets test_many_args_noalloc.bench)
          (deps (:prog capi.exe))
           (action (run orun -o %{targets} -- %{prog} test_many_args_noalloc 200_000_000)))

(alias (name bench) (deps test_no_args_alloc.bench test_no_args_noalloc.bench test_few_args_alloc.bench test_few_args_noalloc.bench test_many_args_alloc.bench test_many_args_noalloc.bench))