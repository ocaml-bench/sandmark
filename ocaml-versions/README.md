# All the compilers

**Why are there so many compiler variants here?**

For Multicore OCaml, these are the compilers that we care about:

* `4.14.0+domains` -- Multicore OCaml compiler
* `5.00.0+trunk` -- Trunk OCaml

We want to get throughput (how fast does it go) and latency (how responsive is
it) results. We also care about serial performance of the multicore compilers.
Since sandmark uses the compiler variants for namespacing results, we have the
following versions:

1. Serial + Throughput
  + `4.12.0+stock.json`
  + `5.00.0+trunk.json`
2. Serial + Latency
  + `4.12.0+stock+instrumented.json` -- compiled with tracing on, which slows down the execution.
3. Parallel + Throughput.
  + `4.14.0+domains.json`
  + `4.12.0+domains.json`
  + `4.12.0+domains+effects.json`
4. Parallel + Latency.
  + `4.12.0+domains+effects+instrumented.json` -- compiled with tracing on, which slows down the execution.
