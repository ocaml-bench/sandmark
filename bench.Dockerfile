FROM ocaml/opam:ubuntu-20.04-ocaml-4.12

ARG BENCH_CPU
ENV BENCH_CPU=$BENCH_CPU

ENV BENCHCMD="$(MAKE) set-bench-cpu/run_config.json; TAG='\"run_in_ci\"' $(MAKE) run_config_filtered.json; USE_SYS_DUNE_HACK=true OPT_WAIT=false RUN_CONFIG_JSON=run_config_filtered.json $(MAKE) ocaml-versions/5.1.0+trunk.bench"

WORKDIR /app

RUN sudo apt-get update
# TODO: Add gnuplot-x11 when irmin benchmarks are enabled
RUN sudo apt-get -y install libgmp-dev libdw-dev jq jo python3-pip pkg-config m4 autoconf libffi-dev cmake libcap2-bin wget

COPY . .

RUN sudo chown -R opam /app
RUN sudo setcap cap_sys_nice=ep /usr/bin/chrt    # for parallel benchmarks
RUN sudo sysctl -w kernel.perf_event_paranoid=-1    # for perf benchmarks
RUN eval $(opam env)

RUN export ITER=1
