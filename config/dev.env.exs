import Mix.Config

config :toru,
  port: {"PORT", "3333", :int},
  lfm_token: {"LFM_TOKEN", :system}

config :exsync, extra_extensions: [".exs"]
