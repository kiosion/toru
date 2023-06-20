defmodule Toru.WS.TrackWebsocket do
  @behaviour :cowboy_websocket

  require Logger

  def init(req, _opts) do
    username = :cowboy_req.binding(:username, req)

    {
      :cowboy_websocket,
      req,
      %{username: username},
      %{
        # 2 minutes w/o a message from the client and the connection is closed
        idle_timeout: 120_000
      }
    }
  end

  def websocket_init(state) do
    Process.flag(:trap_exit, true)

    case Toru.WS.ConnectionManager.increment(state.username) do
      :ok ->
        track_fetcher_pid = Toru.WS.TrackFetcherManager.get_fetcher(state.username)
        Toru.WS.TrackFetcher.subscribe(self(), state.username)
        {:ok, Map.put(state, :track_fetcher_pid, track_fetcher_pid)}

      :error ->
        {:shutdown, :max_connections_reached, state}
    end
  end

  def websocket_terminate(reason, _req, %{
        username: username,
        track_fetcher_pid: track_fetcher_pid
      }) do
    Logger.info("#{username} disconnected")
    Toru.WS.TrackFetcher.unsubscribe(track_fetcher_pid, username)
    Toru.WS.ConnectionManager.decrement(username)
    {:ok, reason}
  end

  def websocket_handle({:close, _code, _reason}, state) do
    {:stop, state}
  end

  def websocket_handle(_msg, state) do
    {:ok, state}
  end

  def websocket_info({:fetch, fetch}, state) do
    Logger.info("Sending message to client")
    fetch_json = Poison.encode!(fetch)
    {:reply, {:text, fetch_json}, state}
  end

  def websocket_info(message, state) do
    IO.inspect({:unexpected_info, message})
    {:ok, state}
  end
end
