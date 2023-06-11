defmodule Toru.Router.WS do
  @behaviour :cowboy_websocket

  require Logger

  def init req, _opts do
    username = :cowboy_req.binding :username, req
    {
      :cowboy_websocket,
      req,
      %{username: username},
      %{
        # 1 min w/o a message from the client and the connection is closed
        idle_timeout: 60_000,
        max_frame_size: 1_000_000, # 1 MB, clients shouldn't have any reason to send more than this
      }
    }
  end

  def websocket_init state do
    Logger.info "new conection for #{state.username}"
    Process.flag :trap_exit, true
    case Toru.WS.ConnectionManager.increment(state.username) do
      :ok ->
        track_fetcher_pid = Toru.WS.TrackFetcherManager.get_fetcher state.username
        Toru.WS.TrackFetcher.subscribe self(), state.username
        {:ok, Map.put(state, :track_fetcher_pid, track_fetcher_pid)}
      :error ->
        {:shutdown, :max_connections_reached, state}
    end
  end

  def terminate reason, _req, %{username: username, track_fetcher_pid: track_fetcher_pid} do
    Logger.info "Terminating connection for #{inspect(self())}-#{username} (#{inspect reason})"
    GenServer.cast track_fetcher_pid, {:unsubscribe, self()}
    Toru.WS.ConnectionManager.decrement username
    :ok
  end

  def websocket_handle {:text, "ping"}, state do
    {:reply, {:text, "pong"}, state}
  end

  def websocket_handle _msg, state do
    {:ok, state}
  end

  def websocket_info({:fetch, fetch}, state) do
    # fetch_json = Poison.encode!(fetch)
    {:reply, {:text, fetch}, state}
  end

  def websocket_info(message, state) do
    Logger.warn {:unexpected_info, message}
    {:ok, state}
  end
end
