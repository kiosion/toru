defmodule Toru.MixProject do
  use Mix.Project

  def project do
    [
      app: :toru,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Toru.MixProject],
      releases: [
        prod: [
          include_executables_for: [:unix],
          steps: [:assemble, :tar],
          validate_compile_env: false
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Toru.Application, []}
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.6"},
      {:poison, "~> 5.0"},
      {:httpoison, "~> 1.8"},
    ]
  end
end
