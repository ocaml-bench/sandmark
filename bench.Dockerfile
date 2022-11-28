FROM ocaml/opam:ubuntu-20.04-ocaml-4.12

ENV BENCHCMD="TAG='\"run_in_ci\"' $(MAKE) run_config_filtered.json; USE_SYS_DUNE_HACK=1 OPT_WAIT=0 RUN_CONFIG_JSON=run_config_filtered.json $(MAKE) ocaml-versions/5.1.0+trunk.bench"

WORKDIR /app

RUN sudo apt-get update
RUN sudo apt-get -y install libgmp-dev libdw-dev jq jo python3-pip pkg-config m4 autoconf gnuplot libffi-dev cmake

COPY . .

RUN sudo chown -R opam /app
RUN sudo setcap cap_sys_nice=ep /usr/bin/chrt
RUN eval $(opam env)

RUN export ITER=1
