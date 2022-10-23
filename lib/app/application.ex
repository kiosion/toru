defmodule Toru.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {
        Plug.Cowboy,
        scheme: :http,
        plug: Toru.Router,
        options: [
          port: Application.get_env(:toru, :port)
        ]
      },
      {
        Plug.Cowboy.Drainer, refs: [Toru.Router]
      }
    ]

    opts = [strategy: :one_for_one, name: Toru.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Application.put_env(:toru, :started_at, System.system_time(:millisecond))
        Logger.info("Toru started")
        Logger.info("ENV: #{Mix.env()}")
        # Return pid of the supervisor
        {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end
end
