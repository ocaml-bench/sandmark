# Contributing multicore benchmarks

If you are contributing a parallel OCaml benchmark, ensure the following:

1. The benchmark should have a serial version with the name `foo`.

1. The benchmark should have a parallel version with the name `foo_multicore`.

   **IMPORTANT**: Parallel version running on 1 domain is not the same as the
   sequential version.

1. The first argument (`params` or `short_name`) should be the number of
   domains. There can be other arguments that follow. When using `short_name`,
   the format should be `<num_domains>_<other_arg>` with an `_` separating the
   number of domains and other arguments.
