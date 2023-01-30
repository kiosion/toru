defmodule Api.V1 do
  use Plug.Router
  use Toru.Assets
  use Toru.Utils

  require Logger

  @themes get_asset(:themes)

  plug(:match)

  plug(:fetch_query_params)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  @spec construct_svg(
          atom
          | %{
              :album => binary,
              :art_radius => any,
              :artist => binary,
              :blur => any,
              :border_radius => any,
              :border_width => any,
              :cover_art => any,
              :mime_type => any,
              :playing => boolean,
              :theme => any,
              :title => binary,
              optional(any) => any
            }
        ) :: binary
  @doc """
  Returns a constructed SVG string based on given parameters
  """
  def construct_svg(params) do
    values = %{
      :title => params.title |> html_encode(),
      :artist => params.artist |> html_encode(),
      :album => params.album |> html_encode(),
      :cover_art => params.cover_art,
      :mime_type => params.mime_type,
      :theme => Map.get(@themes, params.theme, @themes["light"]),
      :border_radius => params.border_radius,
      :art_radius => params.art_radius,
      :border_width => params.border_width,
      :width => 412,
      :height => 128,
      :playing_indicator => playing_indicator(params.playing),
      :line_margin => case params.border_width do
        "0" -> 0
        0 -> 0
        _ -> 4
      end
    }

    values = with true <- params.blur != nil do values |> Map.put(:background_image, get_asset(:background_image)) else _ -> values |> Map.put(:background_image, "") end

    # IO.inspect(values)

    svg = get_asset(:base_svg)

    svg
    |> replace_in_string(values)
    |> String.trim()
    |> String.replace("\r", "")
    |> String.replace(~r{>\s+<}, "><")
  end

  @spec lfm_url!(String.t()) :: String.t()
  defp lfm_url!(username) do
    if username == nil do
      raise "No username specified"
    end

    "http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{username}&api_key=#{Toru.Env.get!(:lfm_token)}&format=json"
  end

  defp set_headers(conn) do
    conn
    |> put_resp_header("content-type", "image/svg+xml")
    |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_header("expires", "0")
  end

  get "/:username" do
    params = fetch_query_params(conn).query_params
    |> validate_query_params(%{
      :theme => "light",
      :border_width => "1.6",
      :border_radius => "22",
      :album_radius => "16",
      :svg_url => nil,
      :url => nil,
      :blur => nil
    })

    with {:ok, res} <- fetch_res(lfm_url!(username)),
         [recent_track | _] <- res |> Map.get("recenttracks", []) |> Map.get("track", []) do
      nowplaying = recent_track
      |> Map.get("@attr", %{})
      |> Map.get("nowplaying", "false")

      cover_art_url = recent_track
      |> Map.get("image", [])
      |> Enum.find(fn image -> image["size"] == "large" end)
      |> Map.get("#text", "")

      cover_art = try do
        with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(cover_art_url) do
          Base.encode64(body)
        else
          {:error, _} -> "" # Eventually, set a fallback image hash here
        end
      rescue
        _ -> ""
      end

      # For backwards compatibility, set 'svg_url' to value of 'url' if it's set
      svgUrl = if params.url != nil or params.svg_url != nil do params.url || params.svg_url end

      svg = case svgUrl do
        url when is_binary(url) ->
          # TODO: If resource is not an svg, return 415
          with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(url) do
            body
            |> replace_in_string(%{
              :title => recent_track["name"],
              :artist => recent_track["artist"]["#text"],
              :album => recent_track["album"]["#text"],
              :cover_art => "data:image/jpeg;base64,#{cover_art}",
              :image => "data:image/jpeg;base64,#{cover_art}",
            }, "${_}")
            |> String.trim()
            |> String.replace("\r", "")
            |> String.replace(~r{>\s+<}, "><")
          else
            _ -> nil
          end
        _ -> nil
      end

      svg = with nil <- svg do
        construct_svg(
          %{
            :title => recent_track["name"],
            :artist => recent_track["artist"]["#text"],
            :album => recent_track["album"]["#text"],
            :playing => nowplaying == "true",
            :cover_art => cover_art,
            :mime_type => "image/jpeg",
            :theme => params.theme,
            :art_radius => params.album_radius,
            :border_radius => params.border_radius,
            :border_width => params.border_width,
            :blur => params.blur
          }
        )
      else
        _ -> svg
      end

      conn
      |> set_headers()
      |> send_resp(200, svg)
    else
      {:error, res} ->
        reason = res.reason
        Logger.notice("Error: #{reason}")

        case res.code do
          404 ->
            conn
            |> set_headers()
            |> send_resp(404, construct_svg(%{
              :title => "Error",
              :artist => "404",
              :album => "User not found",
              :playing => false,
              :cover_art => "",
              :mime_type => "image/jpeg",
              :theme => params.theme,
              :art_radius => params.album_radius,
              :border_radius => params.border_radius,
              :border_width => params.border_width,
              :blur => params.blur
            }))
          _ -> conn |> json_response(500, %{status: 500, message: "Internal Error", detail: reason})
        end
      _ ->
        conn
        |> set_headers()
        |> send_resp(400, construct_svg(%{
          :title => "Error",
          :artist => "400",
          :album => "No recent tracks found",
          :playing => false,
          :cover_art => "",
          :mime_type => "image/jpeg",
          :theme => params.theme,
          :border_radius => params.border_radius,
          :art_radius => params.album_radius,
          :border_width => params.border_width,
          :blur => params.blur
        }))
    end
  end

  get "/" do
    conn |> json_response(400, %{status: 400, message: "Bad Request", detail: "Username not provided"})
  end

  get _ do
    conn |> json_response(404, %{status: 404, message: "Not Found", detail: "The requested resource could not be found or does not exist"})
  end

  match _ do
    path = conn.request_path
    |> case do
      "" -> "/"
      path -> path
    end
    method = conn.method
    conn |> json_response(403, %{status: 403, message: "Forbidden", detail: "Cannot #{method} #{path}"})
  end
end
