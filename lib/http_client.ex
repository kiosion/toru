defmodule Toru.HTTPClient do
  @callback get(String.t(), headers :: list()) ::
              {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
  @callback get(String.t()) ::
              {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Error.t()}
end

defmodule Toru.DefaultHTTPClient do
  @behaviour Toru.HTTPClient

  def get(url, headers) do
    HTTPoison.get(url, headers)
  end

  def get(url) do
    HTTPoison.get(url)
  end
end
