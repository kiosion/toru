defmodule Toru.Utils do
  use Toru.Assets

  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]

  @spec __using__(any) ::
          {:import, [{:column, 7} | {:context, Toru.Utils}, ...],
           [{:__aliases__, [...], [...]}, ...]}
  defmacro __using__(_opts) do
    quote do
      import Toru.Utils
    end
  end

  @spec json_response(Plug.Conn.t(), integer(), map()) :: Plug.Conn.t()
  def json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end

  @spec html_encode(String.t()) :: String.t()
  def html_encode(string) do
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  @spec validate_query_params(map(), map()) :: map()
  def validate_query_params(params, expected) do
    Enum.reduce(expected, %{}, fn {key, default}, acc ->
      if Map.has_key?(params, key) do
        Map.put(acc, key, params[key])
      else
        Map.put(acc, key, default)
      end
    end)
  end

  @spec fetch_resp(String.t()) :: {:error, %{:code => integer(), :reason => String.t()}} | {:ok, map()}
  def fetch_resp(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body |> Poison.decode!()}
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
    end
  end

  @spec playing_indicator(boolean()) :: String.t()
  def playing_indicator(playing) do
    case playing do
      true -> get_asset(:playing_indicator)
      _ -> ""
    end
  end

  @spec replace_in_string(String.t(), map()) :: String.t()
  def replace_in_string(string, replacements) do
    Enum.reduce(replacements, string, fn {key, value}, acc ->
      key = key |> to_string
      # If value is a nested map, then the placeholder should have the key to access in the nested map
      # Example: {{placeholder["key"]}} -> value["key"]
      case is_map(value) do
        true ->
          regex = ~r/{{#{key}\["(.*?)"\]}}/
          Regex.replace(regex, acc, fn _, key -> Map.get(value, key) end)
        _ ->
          regex = ~r/{{#{key}}}/
          Regex.replace(regex, acc, to_string(value))
      end
    end)
  end
end
