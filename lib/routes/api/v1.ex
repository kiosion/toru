defmodule Api.V1 do
  use Plug.Router
  use Toru.Assets
  use Toru.Utils

  require Logger

  @lfm_token Application.compile_env!(:toru, :lfm_token)

  @themes get_asset(:themes)

  plug(:match)

  plug(:fetch_query_params)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  @type svg_params :: %{
    :theme => String.t(),
    :title => String.t(),
    :artist => String.t(),
    :album => String.t(),
    :playing => boolean(),
    :cover_art => String.t(),
    :mime_type => String.t(),
    :bRadius => String.t(),
    :aRadius => String.t(),
    :bWidth => String.t()
  }

  @spec construct_svg(svg_params) :: String.t()
  defp construct_svg(params) do
    values = %{
      :title => params.title |> html_encode(),
      :artist => params.artist |> html_encode(),
      :album => params.album |> html_encode(),
      :cover_art => params.cover_art,
      :mime_type => params.mime_type,
      :theme => Map.get(@themes, params.theme, @themes["light"]),
      :bRadius => params.bRadius,
      :aRadius => params.aRadius,
      :bWidth => params.bWidth,
      :width => 412,
      :height => 128,
      :playing_indicator => playing_indicator(params.playing)
    }

    get_asset(:base_svg)
    |> replace_in_string(values)
    |> String.trim()
    |> String.replace("\r", "")
    |> String.replace(~r{>\s+<}, "><")
  end

  @spec lfm_url(String.t()) :: String.t()
  def lfm_url(username) do
    "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{username}&api_key=#{@lfm_token}&format=json"
  end

  get "/:username" do
    params = fetch_query_params(conn).query_params
    |> validate_query_params(%{"theme" => "light", "border_width" => "1.6", "border_radius" => "22", "album_radius" => "16", "svg_url" => nil, "url" => nil})

    case fetch_resp(lfm_url(username)) do
      {:ok, res} ->
        recent_track = res
        |> Map.get("recenttracks")
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
            :theme => params["theme"],
            :bRadius => params["border_radius"],
            :aRadius => params["album_radius"],
            :bWidth => params["border_width"]
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

          # For backwards compatibility, set 'svg_url' to value of 'url' if it's set
          svgUrl = if params["url"] != nil or params["svg_url"] != nil do params["url"] || params["svg_url"] end

          svg = case svgUrl do
            url when is_binary(url) ->
              # TODO: If resource is not an svg, return 415
              with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(url) do
                body
                |> String.trim()
                |> String.replace("\r", "")
                |> String.replace(~r{>\s+<}, "><")
                |> String.replace("${title}", recent_track["name"])
                |> String.replace("${artist}", recent_track["artist"]["#text"])
                |> String.replace("${album}", recent_track["album"]["#text"])
                |> String.replace("${cover_art}", "data:image/jpeg;base64,#{cover_art}")
                # Also for backwards compatibility :p
                |> String.replace("${image}", "data:image/jpeg;base64,#{cover_art}")
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
                :bRadius => params["border_radius"],
                :bWidth => params["border_width"]
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
        Logger.notice("Error: #{reason}")

        case res.code do
          404 ->
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
              :bRadius => params["border_radius"],
              :bWidth => params["border_width"]
            }))
          _ -> conn |> json_response(500, %{error: 500, message: reason})
        end
    end
  end

  get "/" do
    conn |> json_response(400, %{error: 400, message: "Username not provided"})
  end

  get _ do
    conn |> json_response(404, %{error: 404, message: "The requested resource could not be found or does not exist"})
  end

  match _ do
    path = conn.request_path
    |> case do
      "" -> "/"
      path -> path
    end
    method = conn.method
    conn |> json_response(403, %{error: 403, message: "Cannot #{method} #{path}"})
  end
end
