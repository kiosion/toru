import Mix.Config

config :toru,
  port: {"PORT", "3000", :int},
  lfm_token: {"LFM_TOKEN", "{{LFM_TOKEN}}"},
  env: :prod
