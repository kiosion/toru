defmodule Toru.Utils do
  use Toru.Assets
  use Toru.Cache

  import Plug.Conn, only: [put_resp_content_type: 2, send_resp: 3]

  @html_replacements [
    %{"&" => "&amp;"},
    %{"<" => "&lt;"},
    %{">" => "&gt;"},
    %{"\"" => "&quot;"},
    %{"'" => "&apos;"}
  ]

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

  @spec html_encode(String.t() | Map.t()) :: String.t() | Map.t()
  def html_encode(string) when is_binary(string),
    do:
      Enum.reduce(@html_replacements, string, fn replacement, acc ->
        Map.keys(replacement)
        |> Enum.reduce(acc, fn key, acc -> String.replace(acc, key, Map.get(replacement, key)) end)
      end)

  def html_encode(map) when is_map(map),
    do:
      Enum.reduce(map, %{}, fn {key, value}, acc ->
        Map.put(acc, key, html_encode(value))
      end)

  @doc """
  Take in map of query params and map of expected as `String.t() => String.t()`, return map of `atom => String.t()`
  """
  @spec validate_query_params(map(), map()) :: map()
  def validate_query_params(params, expected) do
    atomized_params = Enum.into(params, %{}, fn {key, value} -> {String.to_atom(key), value} end)

    Enum.reduce(expected, %{}, fn {key, default}, acc ->
      Map.put(acc, key, Map.get(atomized_params, key, default))
    end)
  end

  @spec lfm_url!(String.t()) :: String.t()
  def lfm_url!(username) do
    if username == nil do
      raise "No username specified"
    end

    "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{username |> URI.encode_www_form()}&api_key=#{Toru.Env.get!(:lfm_token)}&format=json&limit=2"
  end

  @spec fetch_res(String.t(), atom()) ::
          {:error, %{:code => integer(), :reason => String.t()}} | {:ok, map()}
  def fetch_res(url, cache \\ :cache) do
    try do
      case cache do
        :cache ->
          with {:ok, value} <- Cache.get(url) do
            {:ok, value}
          else
            _ -> make_http_request(url)
          end

        :no_cache ->
          make_http_request(url)
      end
    rescue
      _ ->
        {:error, %{:code => 500, :reason => "Unknown error fetching data"}}
    end
  end

  defp make_http_request(url) do
    http_client = Application.get_env(:toru, :http_client, Toru.DefaultHTTPClient)

    case http_client.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        value = Poison.decode!(body)
        Cache.put(url, value, 30)
        {:ok, value}

      {:ok, %HTTPoison.Response{status_code: code}} when code in [400, 403, 404, 429] ->
        {:error, %{:code => code, :reason => get_error_reason(code)}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{:code => 500, :reason => reason}}

      _ ->
        {:error, %{:code => 500, :reason => "Unknown upstream error"}}
    end
  end

  defp get_error_reason(400), do: "Invalid request"
  defp get_error_reason(403), do: "Invalid API key"
  defp get_error_reason(404), do: "User not found"
  defp get_error_reason(429), do: "Rate limit exceeded"

  # @spec fetch_res(String.t()) ::
  #         {:error, %{:code => integer(), :reason => String.t()}} | {:ok, map()}
  # def fetch_res(url) do
  #   try do
  #     with {:ok, value} <- Cache.get(url) do
  #       {:ok, value}
  #     else
  #       _ ->
  #         http_client = Application.get_env(:toru, :http_client, Toru.DefaultHTTPClient)

  #         case http_client.get(url) do
  #           {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
  #             value = Poison.decode!(body)
  #             Cache.put(url, value, 30)
  #             {:ok, value}

  #           {:ok, %HTTPoison.Response{status_code: 404}} ->
  #             {:error, %{:code => 404, :reason => "User not found"}}

  #           {:ok, %HTTPoison.Response{status_code: 400}} ->
  #             {:error, %{:code => 400, :reason => "Invalid request"}}

  #           {:ok, %HTTPoison.Response{status_code: 403}} ->
  #             {:error, %{:code => 403, :reason => "Invalid API key"}}

  #           {:ok, %HTTPoison.Response{status_code: 429}} ->
  #             {:error, %{:code => 429, :reason => "Rate limit exceeded"}}

  #           {:error, %HTTPoison.Error{reason: reason}} ->
  #             {:error, %{:code => 500, :reason => reason}}

  #           _ ->
  #             {:error, %{:code => 500, :reason => "Unknown error"}}
  #         end
  #     end
  #   rescue
  #     _ ->
  #       {:error, %{:code => 500, :reason => "Unknown error fetching data"}}
  #   end
  # end

  # def fetch_res(url, :no_cache) do
  #   try do
  #     http_client = Application.get_env(:toru, :http_client, Toru.DefaultHTTPClient)

  #     case http_client.get(url) do
  #       {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
  #         value = Poison.decode!(body)
  #         {:ok, value}

  #       {:ok, %HTTPoison.Response{status_code: 404}} ->
  #         {:error, %{:code => 404, :reason => "User not found"}}

  #       {:ok, %HTTPoison.Response{status_code: 400}} ->
  #         {:error, %{:code => 400, :reason => "Invalid request"}}

  #       {:ok, %HTTPoison.Response{status_code: 403}} ->
  #         {:error, %{:code => 403, :reason => "Invalid API key"}}

  #       {:ok, %HTTPoison.Response{status_code: 429}} ->
  #         {:error, %{:code => 429, :reason => "Rate limit exceeded"}}

  #       {:error, %HTTPoison.Error{reason: reason}} ->
  #         {:error, %{:code => 500, :reason => reason}}

  #       _ ->
  #         {:error, %{:code => 500, :reason => "Unknown error"}}
  #     end
  #   rescue
  #     _ ->
  #       {:error, %{:code => 500, :reason => "Unknown error fetching data"}}
  #   end
  # end

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
