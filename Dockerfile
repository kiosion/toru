FROM elixir:1.14.5-alpine AS builder

RUN apk update && apk add bash openssl libgcc libstdc++ ncurses-libs

ARG LFM_TOKEN

RUN mkdir /app
WORKDIR /app

ADD ./bin/release .
COPY mix.exs mix.lock ./
COPY lib lib
COPY config config

RUN ./release -t $LFM_TOKEN

FROM alpine:3.17.4 AS app

RUN apk update && apk add bash openssl libgcc libstdc++ ncurses-libs

RUN mkdir /app
WORKDIR /app

COPY --from=builder /app/_build ./toru

RUN chown -R nobody: /app
USER nobody

ENV MIX_ENV=prod

ENTRYPOINT ["/app/toru/prod/rel/prod/bin/prod", "start"]
