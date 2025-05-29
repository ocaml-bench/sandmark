# syntax=docker/dockerfile:1
FROM ocaml/opam:ubuntu-22.04-ocaml-4.14

ARG BENCH_CPU
ENV BENCH_CPU=$BENCH_CPU

ENV BENCHCMD="$(MAKE) set-bench-cpu/run_config.json; TAG='\"run_in_ci\"' $(MAKE) run_config_filtered.json; USE_SYS_DUNE_HACK=1 OPT_WAIT=0 RUN_CONFIG_JSON=run_config_filtered.json $(MAKE) ocaml-versions/5.1.0+trunk.bench"

WORKDIR /app

RUN sudo rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' | sudo tee /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    sudo apt update && sudo apt-get --no-install-recommends install -y \
    autoconf \
    cmake \
    jo \
    jq \
    libcap2-bin \
    libdw-dev \
    libffi-dev \
    libgmp-dev \
    m4 \
    pkg-config \
    python3-pip \
    wget
# TODO: Add gnuplot-x11 when irmin benchmarks are enabled

COPY --link . .

RUN sudo chown -R opam /app
RUN sudo setcap cap_sys_nice=ep /usr/bin/chrt    # for parallel benchmarks
RUN sudo sysctl -w kernel.perf_event_paranoid=-1    # for perf benchmarks
RUN eval $(opam env)

RUN export ITER=1
