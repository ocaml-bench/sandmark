# All the compilers

**Why are there so many compiler variants here?**

As far as Multicore OCaml is concerned, these are the relevant compiler
variants:

* `4.06.1+stock` -- Stock OCaml compiler 4.06.1
* `4.06.1+multicore` -- Multicore OCaml compiler 4.06.1
* `4.06.1+multicore+stw` -- Multicore OCaml compiler 4.06.1 with stop-the-world
  parallel minor collector.
* `4.10.0+stock` -- Stock OCaml compiler 4.10.0
* `4.10.0+multicore` -- Multicore OCaml compiler 4.10.0 with stop-the-world parallel minor collector

We want to get throughput (how fast does it go) and latency (how responsive is
it) results. We also care about serial performance of the multicore compilers.
Since sandmark uses the compiler variants for namespacing results, we have the
following versions:

1. Serial + Throughput
  + `4.06.1+stock.comp`
  + `4.06.1+multicore.comp`
  + `4.06.1+multicore+stw.comp`
  + `4.10.0+stock.comp`
  + `4.10.0+multicore.comp`
2. Serial + Latency
  + `4.06.1+stock+instrumented.comp` -- compiled with tracing on, which slows
  down the execution.
  + `4.06.1+multicore+pausetimes.comp` -- same as `4.06.1+multicore.comp`
  + `4.06.1+multicore+stw+pausetimes.comp` -- same as
    `4.06.1+multicore+stw.comp`
  + `4.10.0+stock+instrumented.comp` -- compiled with tracing on, which slows
  down the execution.
  + `4.10.0+multicore+pausetimes.comp` -- same as `4.10.0+multicore.comp`
3. Parallel + Throughput.
  + `4.06.1+multicore+parallel.comp` -- same as `4.06.1+multicore.comp`
  + `4.06.1+multicore+stw+parallel.comp` -- same as `4.06.1+multicore+stw.comp`
  + `4.10.0+multicore+parallel.comp` -- same as `4.10.0+multicore.comp`
4. Parallel + Latency.
  + `4.06.1+multicore+pausetimes+parallel.comp` -- same as
    `4.06.1+multicore.comp`
  + `4.06.1+multicore+stw+pausetimes+parallel.comp` -- same as
    `4.06.1+multicore+stw.comp`
  + `4.10.0+multicore+pausetimes+parallel.comp` -- same as
  `4.10.0+multicore.comp`
