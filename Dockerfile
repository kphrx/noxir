FROM elixir:1.15-slim AS build

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}

WORKDIR /build

COPY mix.exs mix.lock .
RUN mix deps.get

COPY . /build
RUN mix release

FROM elixir:1.15-slim

ENV MIX_ENV=${MIX_ENV}

WORKDIR /app
RUN chown nobody /app

COPY --from=build --chown=nobody:root /build/_build/${MIX_ENV}/rel/noxir .

USER nobody

EXPOSE 4000

CMD ["/app/bin/noxir", "start"]
