# Min elixir version is 1.14 - build for alpine
FROM elixir:1.14-alpine AS build

# Install system deps
RUN apk upgrade --no-cache && \
    apk add --update bash openssl libgcc libstdc++ ncurses-libs

# Set build args
ARG ENV=prod
ARG LFM_TOKEN

# Set build dir
RUN mkdir /app
WORKDIR /app

# Add scripts
ADD ./bin/release .
ADD ./bin/start .

# Copy over source
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib

# Run build script
RUN ./release -t $LFM_TOKEN

# Prepare release image
FROM alpine:3.16.2 AS app

# Install system deps
RUN apk upgrade --no-cache && \
    apk add --update bash openssl libgcc libstdc++ ncurses-libs

# Expose port 3000
EXPOSE 3000
ENV MIX_ENV=$ENV

# Create app dir
RUN mkdir /app
WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build ./toru
COPY --from=build /app/start .
RUN chown -R nobody: /app
USER nobody

# Set runtime env vars
ENV PORT=3000
ENV HOME=/app
ENV MIX_ENV=$ENV

# Entrypoint
ENTRYPOINT ["./start"]
