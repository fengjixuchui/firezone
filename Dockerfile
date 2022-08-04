# This Dockerfile builds a development image to use for local development work

FROM hexpm/elixir:1.13.4-erlang-25.0.3-ubuntu-jammy-20220428

RUN set -xe \
  && apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y apt-utils curl git \
  && curl -sL https://deb.nodesource.com/setup_16.x -o setup_node_deb \
  && bash setup_node_deb \
  && apt-get install -y \
    net-tools \
    iproute2 \
    nftables \
    inotify-tools \
    ca-certificates \
    build-essential \
    sudo \
    nodejs \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm setup_node_deb \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /var/app

ARG GIT_SHA=DEV
ARG MIX_ENV=dev
ARG DATABASE_URL

ENV GIT_SHA=$GIT_SHA
ENV MIX_ENV=$MIX_ENV
ENV DATABASE_URL=$DATABASE_URL

RUN mix local.hex --force && mix local.rebar --force

# Copy more granular, dependency management files first to prevent
# busting the Docker build cache unnecessarily
COPY apps/fz_http/assets/package.json /var/app/apps/fz_http/assets/package.json
COPY apps/fz_http/assets/package-lock.json /var/app/apps/fz_http/assets/package-lock.json
RUN npm install --prefix apps/fz_http/assets

COPY apps/fz_common/mix.exs /var/app/apps/fz_common/mix.exs
COPY apps/fz_http/mix.exs /var/app/apps/fz_http/mix.exs
COPY apps/fz_vpn/mix.exs /var/app/apps/fz_vpn/mix.exs
COPY apps/fz_wall/mix.exs /var/app/apps/fz_wall/mix.exs
COPY mix.exs /var/app/mix.exs
COPY mix.lock /var/app/mix.lock
RUN mix do deps.get, deps.compile, compile

COPY apps /var/app/apps
COPY config /var/app/config

COPY scripts/dev_start.sh /var/app/dev_start.sh

EXPOSE 4000 51820/udp

CMD ["/var/app/dev_start.sh"]
