defmodule Toru.WS.ConnectionManager do
  use GenServer

  @maxConnections 20

  def start_link _args do
    GenServer.start_link __MODULE__, %{}, name: __MODULE__
  end

  def init _ do
    {:ok, %{}}
  end

  @spec increment(String.t()) :: any
  def increment username do
    GenServer.call __MODULE__, {:increment, username}
  end

  @spec decrement(String.t()) :: any
  def decrement username do
    GenServer.call __MODULE__, {:decrement, username}
  end

  def handle_call {:increment, username}, _from, state do
    count = Map.get state, username, 0

    if count == 0 and map_size(state) >= @maxConnections do
      {:reply, :error, state}
    else
      {:reply, :ok, Map.put(state, username, count + 1)}
    end
  end

  def handle_call {:decrement, username}, _from, state do
    count = Map.get state, username, 0

    if count > 1 do
      {:reply, :ok, Map.put(state, username, count - 1)}
    else
      {:reply, :ok, Map.delete(state, username)}
    end
  end
end
