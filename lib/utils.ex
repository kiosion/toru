defmodule Toru.Utils do
  use Toru.Assets
  use Toru.Cache

  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]

  @spec __using__(any) ::
          {:import, [{:column, 7} | {:context, Toru.Utils}, ...],
           [{:__aliases__, [...], [...]}, ...]}
  defmacro __using__(_opts) do
    quote do
      import Toru.Utils
    end
  end

  @spec app_version() :: String.t()
  def app_version(), do: to_string(Application.spec(:toru, :vsn))

  @spec json_response(Plug.Conn.t(), integer(), map()) :: Plug.Conn.t()
  def json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end

  @spec html_encode(String.t()) :: String.t()
  def html_encode(string) do
    replacements = [
      %{"&" => "&amp;"},
      %{"<" => "&lt;"},
      %{">" => "&gt;"},
      %{"\"" => "&quot;"},
      %{"'" => "&apos;"}
    ]

    Enum.reduce(replacements, string, fn replacement, acc ->
      Map.keys(replacement)
      |> Enum.reduce(acc, fn key, acc -> String.replace(acc, key, Map.get(replacement, key)) end)
    end)
  end

  @spec validate_query_params(map(), map()) :: map()
  @doc """
  Take in map of query params and map of expected as `String.t() => String.t()`, return map of `atom => String.t()`
  """
  def validate_query_params(params, expected) do
    atomized_params = Enum.into(params, %{}, fn {key, value} -> {String.to_atom(key), value} end)

    Enum.reduce(expected, %{}, fn {key, default}, acc ->
      Map.put(acc, key, Map.get(atomized_params, key, default))
    end)
  end

  @spec fetch_res(String.t()) :: {:error, %{:code => integer(), :reason => String.t()}} | {:ok, map()}
  def fetch_res(url) do
    with {:ok, value} <- Cache.get(url) do
      {:ok, value}
    else
      _ ->
        case HTTPoison.get(url) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            value = Poison.decode!(body)
            Cache.put(url, value, 30)
            {:ok, value}
          {:ok, %HTTPoison.Response{status_code: 404}} ->
            {:error, %{:code => 404, :reason => "User not found"}}
          {:ok, %HTTPoison.Response{status_code: 400}} ->
            {:error, %{:code => 400, :reason => "Invalid request"}}
          {:ok, %HTTPoison.Response{status_code: 403}} ->
            {:error, %{:code => 403, :reason => "Invalid API key"}}
          {:ok, %HTTPoison.Response{status_code: 429}} ->
            {:error, %{:code => 429, :reason => "Rate limit exceeded"}}
          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, %{:code => 500, :reason => reason}}
          _ ->
            {:error, %{:code => 500, :reason => "Unknown error"}}
        end
    end
  end

  @spec playing_indicator(boolean()) :: String.t()
  def playing_indicator(playing) do
    case playing do
      true -> get_asset(:playing_indicator)
      _ -> ""
    end
  end

  @replace_in_str_pattern_regex ~r/{{(.*?)}}/u
  @replace_in_str_nested_regex ~r/\["(.*?)"\]/u

  @spec replace_in_string!(String.t(), map(), Regex.t() | nil) :: String.t()
  @doc """
  Replace placeholders in a string with values from a map, given an optional placeholder (default: `{{(.*?)}}`)
  """
  def replace_in_string!(string, replacements, pattern \\ @replace_in_str_pattern_regex) do
    Enum.reduce(Regex.scan(pattern, string), string, fn match, acc ->
      [full_match, key] = match

      # Check if key is nested
      if String.contains?(key, "[\"") do
        nested_key = Regex.scan(@replace_in_str_nested_regex, key) |> List.first() |> List.last()
        base_key = key |> String.replace("[\"#{nested_key}\"]", "") |> String.to_atom()
        value = Map.get(replacements, base_key, "")
        new_value = Map.get(value, nested_key, "")
        String.replace(acc, full_match, to_string(new_value))
      else
        atomized_key = String.to_atom(key)
        replacement = Map.get(replacements, atomized_key, "")
        String.replace(acc, full_match, to_string(replacement))
      end
    end)
  end

end
