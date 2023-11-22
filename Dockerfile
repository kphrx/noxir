FROM hexpm/elixir:1.15.7-erlang-26.1.2-debian-bookworm-20231009-slim AS build

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /build

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY . /build
RUN mix release

FROM debian:bookworm-20231009-slim

RUN apt-get update -y && apt-get install --no-install-recommends -y openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /app
RUN chown nobody /app

COPY --from=build --chown=nobody:root /build/_build/${MIX_ENV}/rel/noxir .

USER nobody

EXPOSE 4000

CMD ["/app/bin/noxir", "start"]
