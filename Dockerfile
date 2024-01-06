ARG ELIXIR_VERSION=1.16.0
ARG OTP_VERSION=26.2.1
ARG DEBIAN_VERSION=bookworm-20231009-slim

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} as build

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /build

COPY mix.exs mix.lock ./
RUN mix deps.get

ARG ERL_FLAGS=""
ENV ERL_FLAGS=${ERL_FLAGS}

COPY . /build
RUN mix release

FROM debian:${DEBIAN_VERSION}

RUN apt-get update -y && apt-get install --no-install-recommends -y openssl='3.*' \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LANG C.utf8

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /app
RUN chown nobody /app

COPY --from=build --chown=nobody:root /build/_build/${MIX_ENV}/rel/noxir .

USER nobody

EXPOSE 4000

CMD ["/app/bin/noxir", "start"]
