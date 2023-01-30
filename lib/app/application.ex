defmodule Toru.Application do
  @moduledoc """
  Application module for Toru.
  """

  use Application
  require Logger

  @impl true
  @spec start(:normal | {:takeover, node()} | {:failover, node()}, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {
        Plug.Cowboy,
        scheme: :http,
        plug: Toru.Router,
        options: [
          port: Toru.Env.get!(:port)
        ]
      },
      {
        Plug.Cowboy.Drainer, refs: [:all]
      }
    ]

    opts = [strategy: :one_for_one, name: Toru.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Application.put_env(:toru, :started_at, {"STARTED_AT", "#{System.system_time(:millisecond)}", :int})
        Logger.info("Toru started on port #{Toru.Env.get!(:port)}")
        if Application.get_env(:toru, :lfm_token) == nil do
          Logger.warn("Last.fm API token not set. Some features will not work.")
        end
        {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end
end
