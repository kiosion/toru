FROM elixir:1.10

# By default, should be run in prod
ARG ENV=prod

# Set mix env to the same
ENV MIX_ENV=$ENV

# Working dir within the container
WORKDIR /opt/build

# Add release script to container
ADD ./bin/release ./bin/release

# Entry point
CMD ["bin/release", $ENV]
