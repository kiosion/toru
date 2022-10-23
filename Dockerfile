# Minimum version is 1.14 alpine
FROM elixir:1.14

# By default, should be built for prod
ARG ENV=prod

# Set mix env to the same
ENV MIX_ENV=$ENV

# Working dir within the container
WORKDIR /opt/build

# Add release script to container
ADD ./bin/release ./bin/release

# Also .env
ADD ./.env ./.env

# Entry point
CMD ["./bin/release", $ENV]
