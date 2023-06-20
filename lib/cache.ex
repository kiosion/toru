defmodule Toru.Cache do
  @moduledoc """
  A simple ETS-based cache to store LFM data and images for short periods of time.
  """

  require Logger

  defmacro __using__(_opts) do
    quote do
      alias Toru.Cache, as: Cache
    end
  end

  def setup(max_size \\ 1024) do
    :ets.new(:cache, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    :ets.insert(:cache, {:__max_size, max_size, nil})
  end

  def get(key) do
    entry = :ets.lookup(:cache, key)

    if Toru.Env.get!(:env) == :test do
      nil
    else
      with [{_key, value, expires_at}] <- entry,
           true <- :erlang.system_time(:second) < expires_at do
        {:ok, value}
      else
        [] ->
          # key not found in ETS
          nil

        # key found but expired
        false ->
          :ets.delete(:cache, key)
          nil
      end
    end
  end

  # put with expiry of 60 seconds by default
  def put(key, value) do
    put(key, value, 60)
  end

  def put(key, value, ttl) do
    expires_at = :erlang.system_time(:second) + ttl
    entry = {key, value, expires_at}

    # Only purge if we're inserting a new entry AND
    # we've reached our size limit
    if !exists?(key) && :ets.info(:cache, :size) > get_max_size() do
      purge()
    end

    :ets.insert(:cache, entry)
  end

  def exists?(key) do
    :ets.member(:cache, key)
  end

  defp get_max_size() do
    [{_key, max_size, _nil_ttl}] = :ets.lookup(:cache, :__max_size)
    max_size
  end

  def purge() do
    now = :erlang.system_time(:second)

    :ets.safe_fixtable(:cache, true)

    purge(:ets.first(:cache), now)
  after
    :ets.safe_fixtable(:cache, false)
  end

  defp purge(:"$end_of_table", _now) do
    :ok
  end

  defp purge(key, now) do
    case :ets.lookup(:cache, key) do
      [{_key, _value, expires_at}] when expires_at < now ->
        :ets.delete(:cache, key)

      _ ->
        :ok
    end

    purge(:ets.next(:cache, key), now)
  end
end
