import Mix.Config

config :toru,
  port: System.get_env("PORT") || 4444,
  api_version: System.get_env("API_VERSION") || "v1",
  lfm_token: System.get_env("LFM_TOKEN")
