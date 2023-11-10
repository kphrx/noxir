FROM elixir:1.15-slim AS build

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /build

COPY mix.exs .
COPY mix.lock .
COPY deps deps
RUN mix deps.get

COPY . /build
RUN mix release

FROM elixir:1.15-slim

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /app
COPY --from=build /build/_build/${MIX_ENV}/rel/* .

EXPOSE 4000

CMD ["/app/bin/noxir", "start"]
