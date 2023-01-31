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
    string
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  # Take in map of query params and map of expected as String.t() => String.t(), return map of atom => String.t()
  @spec validate_query_params(map(), map()) :: map()
  def validate_query_params(params, expected) do
    params = Enum.into(params, %{}, fn {key, value} -> {String.to_atom(key), value} end)

    Enum.reduce(expected, %{}, fn {key, default}, acc ->
      if Map.has_key?(params, key) do
        Map.put(acc, key, params[key])
      else
        Map.put(acc, key, default)
      end
    end)
  end

  @spec fetch_res(String.t()) :: {:error, %{:code => integer(), :reason => String.t()}} | {:ok, map()}
  def fetch_res(url) do
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
      _ ->
        {:error, %{:code => 500, :reason => "Unknown error"}}
    end
  end

  @spec playing_indicator(boolean()) :: String.t()
  def playing_indicator(playing) do
    case playing do
      true -> get_asset(:playing_indicator)
      _ -> ""
    end
  end

  @spec replace_in_string!(String.t(), map(), String.t()) :: String.t()
  @doc """
  Replace placeholders in a string with values from a map, given an optional placeholder (default: {{(.*?)}})
  """
  def replace_in_string!(string, replacements, pattern \\ "{{(.*?)}}") do
    with {:ok, regex} <- Regex.compile("#{pattern}"),
         nested_regex <- ~r/\["(.*?)"\]/ do
      regex |> Regex.scan(string) |> Enum.reduce(string, fn match, acc ->
        [full_match, key] = match
        # Check if key is nested
        if String.contains?(key, "[\"") do
          nested_key = Regex.scan(nested_regex, key) |> List.first() |> List.last()
          value = Map.get(replacements, String.replace(key, "[\"#{nested_key}\"]", "") |> String.to_atom())
          acc |> String.replace("#{full_match}", "#{Map.get(value, nested_key)}")
        else
          atomized = key |> String.to_atom()
          if Map.has_key?(replacements, atomized) do
            acc |> String.replace("#{full_match}", "#{Map.get(replacements, atomized)}")
          else
            acc
          end
        end
      end)
    else
      _ -> raise "Invalid pattern: #{pattern}"
    end
  end

end
