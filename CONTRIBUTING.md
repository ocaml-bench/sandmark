# Adding Benchmarks

You can add new benchmarks as follows:

- **Add dependencies to packages:** If there are any package dependencies your
  benchmark has that are not already included in Sandmark, you can add it as a
  dependency to `dependencies/template/dev-*.opam`. If you need to apply any
  patches to the dependency, add its opam file to
  `dependencies/packages/<package-name>/<package-version>/opam`, and the patch
  to the `dependencies/packages/<package-name>/<package-version>/files/`
  directory.

- **Add benchmark files:** Find a relevant folder in `benchmarks/` and add your
  code to it. Feel free to create a new folder if you don't find any existing
  ones relevant. Every folder in `benchmarks/` has its own dune file; if you
  are creating a new directory for your benchmark, also create a dune file in
  that directory and add a stanza for your benchmark. If you are adding your
  benchmark to an existing directory, add a dune stanza for your benchmark in
  the directory's dune file.

  Also add you code and input files if any to an alias,
  `buildbench` for sequential benchmarks and `multibench_parallel` for
  parallel benchmarks. For instance, if you are adding a parallel benchmark
  `benchmark.ml` and its input file `input.txt` to a directory, in that
  directory's dune file add

  ```
  (alias (name multibench_parallel) (deps benchmark.ml input.txt))
  ```

- **Add commands to run your applications:** Add an entry for your benchmark
  run to the appropriate config file; `run_config.json` for sequential
  benchmarks,`multicore_parallel_run_config.json` for parallel benchmarks run
  on `turing` and `multicore_parallel_navajo_run_config.json` for parallel
  benchmarks run on `navajo`.

If you want the benchmark to be run nightly, make sure it has the `macro_bench`
tag.

## Conventions for multicore benchmarks

If you are contributing a parallel OCaml benchmark, ensure the following:

1. The benchmark should have a serial version with the name `foo`.

1. The benchmark should have a parallel version with the name `foo_multicore`.

   **IMPORTANT**: Parallel version running on 1 domain is not the same as the
   sequential version.

1. The first argument (`params` or `short_name`) should be the number of
   domains. There can be other arguments that follow. When using `short_name`,
   the format should be `<num_domains>_<other_arg>` with an `_` separating the
   number of domains and other arguments.
