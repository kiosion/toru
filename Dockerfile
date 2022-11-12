# Pull elixir-alpine image for build stage
FROM elixir:1.14-alpine AS build

# Install build dependencies
RUN apk upgrade --no-cache

RUN apk add --update bash openssl libgcc libstdc++ ncurses-libs

# Set build args
ARG PORT=4000
ARG LFM_TOKEN

# Setup build dir
RUN mkdir /app
WORKDIR /app

# Add scripts
ADD ./bin/release .
ADD ./bin/start .

# Copy over source
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib

# Run build script, passing in build args
RUN ./release -p $PORT -t $LFM_TOKEN

# Prepare release image using alpine linux
FROM alpine:3.16.2 AS app

# Install system dependencies
RUN apk upgrade --no-cache

RUN apk add --update bash openssl libgcc libstdc++ ncurses-libs

# Expose port
EXPOSE $PORT

# Prepare app dir
RUN mkdir /app
WORKDIR /app

# Copy release over from build stage
COPY --from=build /app/_build ./toru
COPY --from=build /app/start .

RUN chown -R nobody: /app
USER nobody

# Set runtime env vars
ENV PORT=$PORT
ENV HOME=/app
ENV MIX_ENV=prod

# Entrypoint
ENTRYPOINT ["./start"]
