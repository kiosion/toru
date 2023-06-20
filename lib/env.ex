defmodule Toru.Env do
  @doc """
  Get a variable from System / Application env and ensure type
  """
  @spec get!(atom()) :: term()
  def get!(key), do: resolve(Application.fetch_env!(:toru, key))

  defp resolve({var, :boolean}), do: System.get_env(var) == "true"
  defp resolve({var, :system}), do: System.get_env(var)
  defp resolve({var, default}), do: System.get_env(var) || default
  defp resolve({var, default, :int}), do: resolve({var, default}) |> parse_int(default)

  defp resolve({var, default, :boolean}) do
    case System.get_env(var) do
      "true" -> true
      val when val in ["", nil] -> default
      _ -> false
    end
  end

  defp resolve(value), do: value

  defp parse_int(value, _default) when is_integer(value), do: value

  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      :error -> default
    end
  end
end
