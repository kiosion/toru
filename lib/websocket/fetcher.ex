defmodule Toru.WS.TrackFetcher do
  use Toru.Utils
  use GenServer

  import Api.V1, only: [get_json: 2]

  def start_link username do
    GenServer.start_link __MODULE__, username, name: via_tuple(username)
  end

  def init username do
    fetch_now()
    schedule_fetch()
    {:ok, %{username: username, subscribers: [], last_fetch: nil}}
  end

  def subscribe pid, username do
    GenServer.call via_tuple(username), {:subscribe, pid}
  end

  def unsubscribe pid, username do
    GenServer.cast via_tuple(username), {:unsubscribe, pid}
  end

  def handle_call {:subscribe, pid}, _from, state do
    subscribers = [pid | state.subscribers]

    if state.last_fetch do
      send pid, {:fetch, state.last_fetch}
    end

    {:reply, :ok, %{state | subscribers: subscribers}}
  end

  def handle_cast {:unsubscribe, pid}, state do
    IO.puts "Unsubscribing #{inspect(pid)} from #{inspect(state.username)}"
    subscribers = List.delete state.subscribers, pid

    if subscribers == [] do
      Process.send_after self(), :stop, 0
      {:noreply, state}
    else
      {:noreply, %{state | subscribers: subscribers}}
    end
  end

  def handle_info :fetch, state do
    fetch = fetch_current_track state.username
    if fetch == state.last_fetch do
      {:noreply, state}
    else
      for pid <- state.subscribers, do: send(pid, {:fetch, fetch})
      {:noreply, %{state | last_fetch: fetch}}
    end
  end

  def handle_info :fetch_schedule, state do
    fetch_now()
    schedule_fetch()
    {:noreply, state}
  end

  def handle_info :stop, state do
    IO.puts "Stopping fetcher for #{inspect(state.username)}"
    Toru.WS.TrackFetcherManager.stop_fetcher state.username
    {:stop, :normal, state}
  end

  def handle_info _msg, state do
    {:noreply, state}
  end

  defp via_tuple username do
    {:via, Registry, {Toru.WS.TrackRegistry, username}}
  end

  defp fetch_now do
    Process.send_after self(), :fetch, 0
  end

  defp schedule_fetch do
    Process.send_after self(), :fetch_schedule, 15_000 # 15 seconds
  end

  defp fetch_current_track username do
    with {:ok, res}         <- fetch_res(lfm_url!(username), :no_cache),
         [recent_track | _] <- res |> Map.get("recenttracks", []) |> Map.get("track", []) do
      Poison.encode!(get_json(%{}, recent_track))
    else
      _ -> nil
    end
  end
end
