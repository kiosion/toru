defmodule ToruApplicationTest do
  use ExUnit.Case
  use Plug.Test

  import Mox

  doctest Toru.Application

  setup :verify_on_exit!
  setup :set_mox_global

  Mox.defmock(Toru.MockHTTPClient, for: Toru.HTTPClient)

  setup do
    Application.put_env(:toru, :http_client, Toru.MockHTTPClient)
    :ok
  end

  @opts Toru.Router.init([])

  test "GET /" do
    conn =
      conn(:get, "/")
      |> Toru.Router.call(@opts)

    assert conn.state == :sent
    # Shouldn't be able to GET non-api routes
    assert conn.status == 403

    body = Poison.decode!(conn.resp_body)

    assert body["message"] == "Forbidden"
  end

  test "GET svg res from API" do
    mock_response = %HTTPoison.Response{
      body: Poison.encode!(stub_json()),
      status_code: 200
    }

    Toru.MockHTTPClient
    |> Mox.expect(
      :get,
      2,
      fn url ->
        if String.contains?(url, "format=json") do
          {:ok, mock_response}
        else
          {:ok, %HTTPoison.Response{body: "", status_code: 200}}
        end
      end
    )

    conn =
      conn(:get, "/api/v1/kiosion")
      |> Toru.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    body = conn.resp_body

    # Check for strings within the SVG for now
    assert String.contains?(body, "Far Out")
    assert String.contains?(body, "Stay With Me - Extended Mix")
  end

  test "Filling in provided (valid) SVG" do
    mock_lfm_response = %HTTPoison.Response{
      body: Poison.encode!(stub_json()),
      status_code: 200
    }

    mock_svg_response = %HTTPoison.Response{
      body: "<svg>${artist}</svg>",
      status_code: 200,
      headers: [{"content-type", "image/svg+xml"}]
    }

    Toru.MockHTTPClient
    |> Mox.expect(
      :get,
      3,
      fn url ->
        cond do
          String.contains?(url, "format=json") ->
            {:ok, mock_lfm_response}

          String.contains?(url, "example.com") ->
            {:ok, mock_svg_response}

          true ->
            {:ok, %HTTPoison.Response{body: "", status_code: 200}}
        end
      end
    )

    conn =
      conn(:get, "/api/v1/kiosion?svg_url=https://example.com")
      |> Toru.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    body = conn.resp_body

    assert String.contains?(body, "Far Out")
  end

  test "Filling in provided (invalid) svg" do
    mock_lfm_response = %HTTPoison.Response{
      body: Poison.encode!(stub_json()),
      status_code: 200
    }

    mock_svg_response = %HTTPoison.Response{
      body: "",
      status_code: 200
    }

    Toru.MockHTTPClient
    |> Mox.expect(
      :get,
      3,
      fn url ->
        cond do
          String.contains?(url, "format=json") ->
            {:ok, mock_lfm_response}

          String.contains?(url, "example.com") ->
            {:ok, mock_svg_response}

          true ->
            {:ok, %HTTPoison.Response{body: "", status_code: 200}}
        end
      end
    )

    conn =
      conn(:get, "/api/v1/kiosion?svg_url=https://example.com")
      |> Toru.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 415

    body = Poison.decode!(conn.resp_body)

    assert body["message"] == "Provided SVG resource is not of type image/svg+xml"
  end

  test "GET json res from API" do
    mock_response = %HTTPoison.Response{
      body: Poison.encode!(stub_json()),
      status_code: 200
    }

    Toru.MockHTTPClient
    |> Mox.expect(
      :get,
      2,
      fn url ->
        if String.contains?(url, "format=json") do
          {:ok, mock_response}
        else
          {:ok, %HTTPoison.Response{body: "", status_code: 200}}
        end
      end
    )

    conn =
      conn(:get, "/api/v1/kiosion?res=json")
      |> Toru.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    expected = %{
      "status" => 200,
      "data" => %{
        "title" => "Stay With Me - Extended Mix",
        "artist" => "Far Out",
        "album" => "Stay With Me",
        "playing" => true,
        "streamable" => false,
        "cover_art" => %{
          "data" => "",
          "mime_type" => "image/jpeg"
        },
        "url" => "https://www.last.fm/music/Far+Out/_/Stay+With+Me+-+Extended+Mix"
      }
    }

    body = Poison.decode!(conn.resp_body)

    assert body == expected
  end

  defp stub_json do
    %{
      :recenttracks => %{
        :track => [
          %{
            :artist => %{
              :mbid => "",
              :"#text" => "Far Out"
            },
            :streamable => "0",
            :image => [
              %{
                :size => "small",
                :"#text" =>
                  "https://lastfm.freetls.fastly.net/i/u/34s/fabaa95c087507009f663dd221f959a5.jpg"
              },
              %{
                :size => "medium",
                :"#text" =>
                  "https://lastfm.freetls.fastly.net/i/u/64s/fabaa95c087507009f663dd221f959a5.jpg"
              },
              %{
                :size => "large",
                :"#text" =>
                  "https://lastfm.freetls.fastly.net/i/u/174s/fabaa95c087507009f663dd221f959a5.jpg"
              }
            ],
            :mbid => "",
            :album => %{
              :mbid => "",
              :"#text" => "Stay With Me"
            },
            :name => "Stay With Me - Extended Mix",
            :"@attr" => %{
              :nowplaying => "true"
            },
            :url => "https://www.last.fm/music/Far+Out/_/Stay+With+Me+-+Extended+Mix"
          }
        ]
      }
    }
  end
end
