import Mix.Config

config :toru,
  port: System.get_env("PORT") || 3333,
  lfm_token: System.get_env("LFM_TOKEN")
