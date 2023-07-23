FROM elixir:1.14.5-alpine AS build

RUN apk update && apk add bash openssl libgcc libstdc++ ncurses-libs

ARG LFM_TOKEN

WORKDIR /app

ADD ./bin/release .
COPY mix.exs mix.lock ./
COPY lib lib
COPY config config

RUN ./release $LFM_TOKEN

FROM alpine:3.17.4 AS app

RUN apk update && apk add bash openssl libgcc libstdc++ ncurses-libs

WORKDIR /app

COPY --from=build /app/_build ./toru

RUN chown -R nobody: /app
USER nobody

ENV MIX_ENV=prod

ENTRYPOINT ["/app/toru/prod/rel/prod/bin/prod", "start"]
