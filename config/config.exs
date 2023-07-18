import Config

config :toru,
  env: config_env()

import_config "#{config_env()}.env.exs"
