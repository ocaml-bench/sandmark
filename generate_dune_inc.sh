cd benchmarks
for b in $(find * -type d); do
    echo "(rule
  (targets $b.perf)
  (deps (:prog $b.exe))
  (action (run perf stat -ax'|' -o %{targets} ./%{prog})))
(alias (name bench-run) (deps $b.perf))" > $b/dune.inc; done
