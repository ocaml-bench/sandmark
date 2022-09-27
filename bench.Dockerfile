FROM ocaml/opam:ubuntu-20.04-ocaml-4.12

ENV BENCHCMD="TAG='\"run_in_ci\"' $(MAKE) run_config_filtered.json; RUN_CONFIG_JSON=run_config_filtered.json $(MAKE) ocaml-versions/5.1.0+trunk.bench"

WORKDIR /app

RUN sudo apt-get update
RUN sudo apt-get -y install libgmp-dev libdw-dev jq jo python3-pip pkg-config m4 autoconf

RUN opam update
RUN opam install dune.2.9.0

COPY . .

RUN sudo chown -R opam /app
RUN eval $(opam env)

RUN export ITER=1
