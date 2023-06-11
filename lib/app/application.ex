defmodule Toru.Application do
  @moduledoc """
  Application module for Toru.
  """

  use Application
  require Logger

  defp dispatch do
    [
      {:_, [
        {"/api/v1/ws/:username", Toru.Router.WS, []},
        {:_, Plug.Cowboy.Handler, {Toru.Router, []}},
      ]}
    ]
  end

  @impl true
  @spec start(:normal | {:takeover, node()} | {:failover, node()}, any) :: {:error, any} | {:ok, pid}
  def start _type, _args do
    children = [
      Toru.WS.ConnectionManager,
      {
        Registry,
        keys: :unique,
        name: Toru.WS.TrackRegistry
      },
      Toru.WS.TrackFetcherManager,
      {
        Plug.Cowboy,
        scheme: :http,
        plug: Toru.Router,
        options: [
          port: Toru.Env.get!(:port),
          dispatch: dispatch(),
        ]
      },
      {
        Plug.Cowboy.Drainer, refs: [:all]
      },
    ]

    opts = [strategy: :one_for_one, name: Toru.Supervisor]

    case Supervisor.start_link children, opts do
      {:ok, pid} ->
        Toru.Cache.setup()
        Application.put_env :toru, :started_at, {"STARTED_AT", "#{System.system_time(:millisecond)}", :int}
        Logger.info "Toru started on port #{Toru.Env.get!(:port)}"

        if Toru.Env.get!(:lfm_token) == nil || Toru.Env.get!(:lfm_token) == "" do
          Logger.warn("Last.fm API token not set.")
        end

        {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end
end
