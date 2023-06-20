defmodule Toru.MixProject do
  use Mix.Project

  def project do
    [
      app: :toru,
      version: "2.7.0",
      elixir: "~> 1.13",
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
    depsl = [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:httpoison, "~> 2.0"},
      {:mox, "~> 1.0", only: :test},
      {:plug_cowboy, "~> 2.6"},
      {:poison, "~> 4.0"}
    ]

    case Mix.env() do
      :dev ->
        depsl ++
          [
            {:exsync, "~> 0.2"},
            {:file_system, "~> 0.2"}
          ]

      _ ->
        depsl
    end
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
