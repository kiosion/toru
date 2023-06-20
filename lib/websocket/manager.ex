defmodule Toru.WS.TrackFetcherManager do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def get_fetcher(username) do
    GenServer.call(__MODULE__, {:get_fetcher, username})
  end

  def stop_fetcher(username) do
    GenServer.call(__MODULE__, {:stop_fetcher, username})
  end

  def handle_call({:get_fetcher, username}, _from, _state) do
    fetcher = get_fetcher_for_username(username)
    {:reply, fetcher, %{}}
  end

  def handle_call({:stop_fetcher, username}, _from, _state) do
    stop_fetcher_for_username(username)
    {:reply, :ok, %{}}
  end

  defp get_fetcher_for_username(username) do
    case Registry.lookup(Toru.WS.TrackRegistry, username) do
      [{pid, _}] ->
        pid

      [] ->
        {:ok, pid} = Toru.WS.TrackFetcher.start_link(username)

        case Registry.register(Toru.WS.TrackRegistry, username, []) do
          {:ok, _pid} -> pid
          {:error, {:already_registered, _pid}} -> pid
        end
    end
  end

  defp stop_fetcher_for_username(username) do
    case Registry.lookup(Toru.WS.TrackRegistry, username) do
      [{pid, _}] ->
        Process.unlink(pid)
        Process.exit(pid, :normal)
        :ok = Registry.unregister(Toru.WS.TrackRegistry, username)
        {:ok, pid}

      [] ->
        {:ok, nil}
    end
  end
end
