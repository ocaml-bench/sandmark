# All the compilers

**Why are there so many compiler variants here?**

As far as Multicore OCaml is concerned, these are the relevant compiler
variants:

* `4.12.0+stock` -- Stock OCaml compiler 4.12.0
* `4.12.0+domains` -- Multicore OCaml compiler 4.12.0 with only domains
* `4.12.0+domains+effects` -- Multicore OCaml compiler 4.12.0 with domains and effects

We want to get throughput (how fast does it go) and latency (how responsive is
it) results. We also care about serial performance of the multicore compilers.
Since sandmark uses the compiler variants for namespacing results, we have the
following versions:

1. Serial + Throughput
  + `4.06.1+stock.json`
  + `4.06.1+multicore.json`
  + `4.06.1+multicore+stw.json`
  + `4.10.0+stock.json`
  + `4.10.0+multicore.json`
  + `4.12.0+stock.json`
2. Serial + Latency
  + `4.06.1+stock+instrumented.json` -- compiled with tracing on, which slows
  down the execution.
  + `4.06.1+multicore+pausetimes.json` -- same as `4.06.1+multicore.json`
  + `4.06.1+multicore+stw+pausetimes.json` -- same as
    `4.06.1+multicore+stw.json`
  + `4.10.0+stock+instrumented.json` -- compiled with tracing on, which slows
  down the execution.
  + `4.10.0+multicore+pausetimes.json` -- same as `4.10.0+multicore.json`
3. Parallel + Throughput.
  + `4.06.1+multicore+parallel.json` -- same as `4.06.1+multicore.json`
  + `4.06.1+multicore+stw+parallel.json` -- same as `4.06.1+multicore+stw.json`
  + `4.10.0+multicore+parallel.json` -- same as `4.10.0+multicore.json`
  + `4.12.0+domains.json`
  + `4.12.0+domains+effects.json`
4. Parallel + Latency.
  + `4.06.1+multicore+pausetimes+parallel.json` -- same as
    `4.06.1+multicore.json`
  + `4.06.1+multicore+stw+pausetimes+parallel.json` -- same as
    `4.06.1+multicore+stw.json`
  + `4.10.0+multicore+pausetimes+parallel.json` -- same as
  `4.10.0+multicore.json`
