import Mix.Config

import_config "#{Mix.env()}.env.exs"

config :exsync, extra_extensions: [".exs"]

