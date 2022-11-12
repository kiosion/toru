defmodule Toru.Router.Api.V1 do
  use Plug.Router
  use Plug.ErrorHandler

  require Logger

  @lfm_token Application.compile_env!(:toru, :lfm_token)

  # Maps for default themes
  @themes %{
    "light" => %{
      "background" => "#F2F2F2",
      "text" => "#1A1A1A",
      "accent" => "#8C8C8C"
    },
    "dark" => %{
      "background" => "#1A1A1A",
      "text" => "#E6E6E6",
      "accent" => "#CCCCCC"
    },
    "shoji" => %{
      "background" => "#E8E8E3",
      "text" => "#4D4D4D",
      "accent" => "#4D4D4D"
    },
    "solarized" => %{
      "background" => "#FDF6E3",
      "text" => "#657B83",
      "accent" => "#839496"
    },
    "dracula" => %{
      "background" => "#282A36",
      "text" => "#F8F8F2",
      "accent" => "#6272A4"
    },
    "nord" => %{
      "background" => "#2E3440",
      "text" => "#ECEFF4",
      "accent" => "#81A1C1"
    }
  }

  plug(:match)

  plug(:fetch_query_params)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

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
  defp validate_query_params(params, expected) do
    Enum.reduce(expected, %{}, fn {key, default}, acc ->
      if Map.has_key?(params, key) do
        Map.put(acc, key, params[key])
      else
        Map.put(acc, key, default)
      end
    end)
  end

  @type svg_params :: %{
    :theme => String.t(),
    :title => String.t(),
    :artist => String.t(),
    :album => String.t(),
    :playing => boolean(),
    :cover_art => String.t(),
    :mime_type => String.t(),
    :bRadius => String.t(),
    :aRadius => String.t()
  }

  @spec construct_svg(svg_params) :: String.t()
  defp construct_svg(params) do
    title = params.title |> html_encode()
    artist = params.artist |> html_encode()
    album = params.album |> html_encode()
    playing = params.playing
    cover_art = params.cover_art
    mime_type = params.mime_type
    theme = Map.get(@themes, params.theme, @themes["light"])
    bRadius = params.bRadius
    aRadius = params.aRadius
    width = 412
    height = 128

    playing_indicator = if playing, do: """
      <div class="bars"><span class="bar"/><span class="bar"/><span class="bar"/></div>
    """, else: ""

    svg = """
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xhtml="http://www.w3.org/1999/xhtml" width="#{width}" height="#{height}">
        <foreignObject width="#{width}" height="#{height}">
          <style>.bars{position:relative;display:inline-flex;justify-content:space-between;width:12px;height:9px;margin-right:5px;}.bar{width:2.5px;height:100%;background-color:#{theme["accent"]};border-radius:10000px;transform-origin:bottom;animation:bounce 0.8s ease infinite alternate;content:'';}.bar:nth-of-type(2){animation-delay:-0.8s;}.bar:nth-of-type(3){animation-delay:-1.2s;}@keyframes bounce{0%{transform:scaleY(0.1);}100%{transform:scaleY(1);}}</style>
          <div xmlns="http://www.w3.org/1999/xhtml" style="display:flex;flex-direction:row;justify-content:flex-start;align-items:center;width:100%;height:100%;border-radius:#{bRadius}px;background-color:#{theme["background"]};color:#{theme["text"]};padding:0 14px;box-sizing:border-box; overflow:clip;">
            <div style="display:flex;height:fit-content;width:fit-content;">
              <img src="data:#{mime_type};base64,#{cover_art}" alt="Cover" style="border:1.6px solid #{theme["accent"]};border-radius:#{aRadius}px; background-color:#{theme["background"]}" width="100px" height="100px"/>
            </div>
            <div style="display:flex;flex-direction:column;padding-left:14px;">
              <span style="font-family:'Century Gothic',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.5rem;font-size:20px;font-weight:bold;padding-bottom:6px;border-bottom:1.6px solid #{theme["accent"]};">#{title}</span>
              <div style="display:flex;flex-direction:row;justify-content:flex-start;align-items:baseline;width:100%;height:100%;">
                <span style="font-family:'Century Gothic',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;line-height:1.5rem;font-size:16px;font-weight:normal;margin-top:4px;">#{playing_indicator}#{artist} - #{album}</span>
              </div>
            </div>
          </div>
        </foreignObject>
      </svg>
    """
    svg
    |> String.trim()
    |> String.replace("\r", "")
    |> String.replace(~r{>\s+<}, "><")
  end

  @spec fetch_info(String.t()) :: {:error, %{:code => integer(), :reason => String.t()}} | {:ok, map()}
  def fetch_info(username) do
    url = "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{username}&api_key=#{@lfm_token}&format=json"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body |> Poison.decode!() |> Map.get("recenttracks")}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, %{:code => 404, :reason => "User not found"}}
      {:ok, %HTTPoison.Response{status_code: 400}} ->
        {:error, %{:code => 400, :reason => "Invalid request"}}
      {:ok, _} ->
        {:error, %{:code => 500, :reason => "Unknown response"}}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{:code => 500, :reason => reason}}
    end
  end

  get "/:username" do
    params = fetch_query_params(conn).query_params
    |> validate_query_params(%{"theme" => "light", "border_radius" => "22", "album_radius" => "16", "svg_url" => nil})

    case fetch_info(username) do
      {:ok, res} ->
        recent_track = res
        |> Map.get("track", [])
        |> List.first()

        # If recent_track is nil, skip the rest of the fn & return error state svg
        if recent_track == nil do
          conn
          |> put_resp_content_type("image/svg+xml")
          |> send_resp(200, construct_svg(%{
            :title => "Error",
            :artist => "400",
            :album => "No recent tracks found",
            :playing => false,
            :cover_art => "",
            :mime_type => "image/jpeg",
            :theme => params.theme,
            :bRadius => params.border_radius,
            :aRadius => params.album_radius
          }))
        else
          nowplaying = recent_track
          |> Map.get("@attr", %{})
          |> Map.get("nowplaying", "false")

          cover_art_url = recent_track
          |> Map.get("image", [])
          |> Enum.find(fn image -> image["size"] == "large" end)
          |> Map.get("#text", "")

          cover_art = with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(cover_art_url) do
            Base.encode64(body)
          else
            {:error, _} -> "" # Eventually, set a fallback image hash here
          end

          svg = case params["svg_url"] do
            url when is_binary(url) ->
              with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(url) do
                body
                |> String.replace("${title}", recent_track["name"])
                |> String.replace("${artist}", recent_track["artist"]["#text"])
                |> String.replace("${album}", recent_track["album"]["#text"])
                |> String.replace("${cover_art}", "data:image/jpeg;base64,#{cover_art}")
              else
                _ -> nil
              end
            _ -> nil
          end

          svg = if svg == nil do
            construct_svg(
              %{
                :title => recent_track["name"],
                :artist => recent_track["artist"]["#text"],
                :album => recent_track["album"]["#text"],
                :playing => nowplaying == "true",
                :cover_art => cover_art,
                :mime_type => "image/jpeg",
                :theme => params["theme"],
                :aRadius => params["album_radius"],
                :bRadius => params["border_radius"]
              }
            )
          else
            svg
          end

          conn
          |> put_resp_header("content-type", "image/svg+xml")
          |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
          |> put_resp_header("pragma", "no-cache")
          |> put_resp_header("expires", "0")
          |> send_resp(200, svg)
        end
      {:error, res} ->
        reason = res.reason
        code = res.code
        Logger.notice("Error: #{reason}")
        if code == 404 do
          conn
          |> put_resp_content_type("image/svg+xml")
          |> send_resp(200, construct_svg(%{
            :title => "Error",
            :artist => "404",
            :album => "User not found",
            :playing => false,
            :cover_art => "",
            :mime_type => "image/jpeg",
            :theme => params["theme"],
            :aRadius => params["album_radius"],
            :bRadius => params["border_radius"]
          }))
        else
          json_response(conn, 500, %{status: 500, message: reason})
        end
    end
  end

  get "/" do
    json_response(conn, 400, %{status: 400, message: "Username not provided"})
  end

  match _ do
    json_response(conn, 404, %{status: 404, message: "Route or resource not found"})
  end
end
