defmodule Toru.MixProject do
  use Mix.Project

  def project do
    [
      app: :toru,
      version: "2.7.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Toru.MixProject],
      releases: releases()
    ]
  end

  def application do
    case Mix.env() do
      :dev ->
        [
          extra_applications: [:logger, :runtime_tools],
          mod: {
            Toru.Application,
            []
          }
        ]

      _ ->
        [
          extra_applications: [:logger],
          mod: {
            Toru.Application,
            []
          }
        ]
    end
  end

  defp deps do
    [
      {:exsync, "~> 0.2", only: :dev},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:file_system, "~> 1.0", only: :dev},
      {:httpoison, "~> 2.0"},
      {:mox, "~> 1.0", only: :test},
      {:plug_cowboy, "~> 2.6"},
      {:poison, "~> 6.0"}
    ]
  end

  defp releases do
    [
      prod: [
        include_executables_for: [:unix],
        steps: [:assemble, :tar]
      ]
    ]
  end
end
