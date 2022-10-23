import Mix.Config

config :toru,
  port: System.get_env("PORT") || 4000,
  api_version: System.get_env("API_VERSION") || "v1",
  lfm_api_key: ${LFM_API_KEY}
