defmodule Toru.MixProject do
  use Mix.Project

  def project do
    [
      app: :toru,
      version: "2.1.2",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Toru.MixProject],
      releases: releases()
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
      {:poison, "~> 4.0"},
      {:httpoison, "~> 1.8"},
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
