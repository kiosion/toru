defmodule Api.V1 do
  use Plug.Router
  use Toru.Assets
  use Toru.Utils
  use Toru.Cache

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
      :line_margin =>
        case params.border_width do
          "0" -> 0
          0 -> 0
          _ -> 4
        end
    }

    values =
      with true <- params.blur != nil do
        values
        |> Map.put(
          :background_image,
          get_asset(:background_image) |> replace_in_string!(values)
        )
      else
        _ -> values |> Map.put(:background_image, "")
      end

    get_asset(:base_svg)
    |> replace_in_string!(values)
    |> String.trim()
    |> String.replace("\r", "")
    |> String.replace(~r{>\s+<}, "><")
  end

  @spec fetch_cover_art(String.t()) :: binary
  defp fetch_cover_art(url) do
    # Eventually, set a fallback image hash here
    fallback = %{:mime_type => "", :data => ""}

    with {:ok, res} <- Cache.get(url) do
      res
    else
      _ ->
        try do
          with {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} <-
                 Application.get_env(:toru, :http_client, Toru.DefaultHTTPClient).get(url) do
            mime_type =
              headers
              |> Enum.find(fn {k, _} -> k == "Content-Type" end)
              |> case do
                {_, v} -> v
                _ -> "image/jpeg"
              end

            res = %{:mime_type => mime_type, :data => Base.encode64(body)}
            Cache.put(url, res, 24 * 60 * 60)
            res
          else
            {:error, e} ->
              Logger.error("Error fetching cover art, HTTPoison error: #{inspect(e)}")
              fallback
          end
        rescue
          e ->
            Logger.error("Error fetching cover art, rescued from: #{inspect(e)}")
            fallback
        end
    end
  end

  @spec set_headers(Plug.Conn.t()) :: Plug.Conn.t()
  defp set_headers(conn) do
    conn
    |> put_resp_header("content-type", "image/svg+xml")
    |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header(
      "access-control-allow-headers",
      "content-type, access-control-allow-headers, access-control-allow-origin, accept"
    )
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_header("expires", "0")
  end

  @spec default_params() :: map()
  defp default_params,
    do: %{
      :theme => "light",
      :border_width => "1.6",
      :border_radius => "22",
      :album_radius => "18",
      :svg_url => nil,
      :url => nil,
      :blur => nil,
      :res => "svg",
      :cover_size => "large"
    }

  defp start_cover_art_task(params, recent_track) do
    Task.async(fn ->
      req_size =
        with true <- params != nil,
             true <- params != %{} do
          case params.cover_size do
            "large" -> "large"
            "medium" -> "medium"
            "small" -> "small"
            _ -> "large"
          end
        else
          _ -> "medium"
        end

      avail_images = recent_track |> Map.get("image", [])

      Enum.find(avail_images, fn image ->
        image["size"] == req_size
      end)
      |> case do
        nil -> Enum.max_by(avail_images, & &1["size"])
        image -> image
      end
      |> Map.get("#text", "")
      |> fetch_cover_art()
    end)
  end

  def get_svg(params, recent_track) do
    nowplaying =
      recent_track
      |> Map.get("@attr", %{})
      |> Map.get("nowplaying", "false")
      |> (fn s -> s == "true" end).()

    cover_art = start_cover_art_task(params, recent_track)

    # For backwards compatibility, set 'svg_url' to value of 'url' if it's set
    svgUrl =
      with true <- params.url != nil do
        params.url
      else
        false ->
          with true <- params.svg_url != nil do
            params.svg_url
          else
            false -> nil
          end

        _ ->
          nil
      end

    svg =
      case svgUrl do
        url when is_binary(url) ->
          # TODO: If resource is not an svg, return 415
          with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
                 Application.get_env(:toru, :http_client, Toru.DefaultHTTPClient).get(url) do
            body
          else
            _ -> nil
          end

        _ ->
          nil
      end

    %{data: cover_art_data, mime_type: cover_art_mime_type} = Task.await(cover_art)

    svg =
      with nil <- svg do
        construct_svg(%{
          :title => recent_track["name"],
          :artist => recent_track["artist"]["#text"],
          :album => recent_track["album"]["#text"],
          :playing => nowplaying,
          :cover_art => cover_art_data,
          :mime_type => cover_art_mime_type,
          :theme => params.theme,
          :art_radius => params.album_radius,
          :border_radius => params.border_radius,
          :border_width => params.border_width,
          :blur => params.blur
        })
      else
        _ ->
          svg
          |> replace_in_string!(
            %{
              :title => recent_track["name"],
              :artist => recent_track["artist"]["#text"],
              :album => recent_track["album"]["#text"],
              :cover_art => "data:#{cover_art_mime_type};base64,#{cover_art_data}",
              :image => "data:#{cover_art_mime_type};base64,#{cover_art_data}"
            },
            ~r/\${(.*?)}/u
          )
      end

    svg
  end

  def get_json(params, recent_track) do
    cover_art = start_cover_art_task(params, recent_track)

    %{data: cover_art_data, mime_type: cover_art_mime_type} = Task.await(cover_art)

    %{
      "title" => recent_track["name"],
      "album" => recent_track["album"]["#text"],
      "artist" => recent_track["artist"]["#text"],
      "playing" => recent_track["@attr"]["nowplaying"] == "true",
      "cover_art" => %{
        "data" => cover_art_data,
        "mime_type" => cover_art_mime_type
      },
      "url" => recent_track["url"],
      "streamable" => recent_track["streamable"] == "1"
    }
  end

  options "/:username" do
    conn
    |> put_resp_header("access-control-allow-methods", "GET, OPTIONS")
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header(
      "access-control-allow-headers",
      "content-type, access-control-allow-headers, access-control-allow-origin, accept"
    )
    |> send_resp(200, "")
  end

  get "/:username" do
    params = fetch_query_params(conn).query_params |> validate_query_params(default_params())

    with {:ok, res} <- fetch_res(lfm_url!(username)),
         [recent_track | _] <- res |> Map.get("recenttracks", []) |> Map.get("track", []) do
      if params.res == "json" do
        json_info = get_json(params, recent_track)

        conn
        |> set_headers()
        |> put_resp_header("content-type", "application/json")
        |> send_resp(
          200,
          Poison.encode!(%{
            :status => 200,
            :data => json_info
          })
        )
      else
        svg = get_svg(params, recent_track)

        conn
        |> set_headers()
        |> send_resp(200, svg)
      end
    else
      {:error, res} ->
        reason = res.reason
        Logger.notice("Error: #{reason}")

        case res.code do
          404 ->
            conn
            |> set_headers()
            |> send_resp(
              404,
              construct_svg(%{
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
              })
            )

          _ ->
            conn |> json_response(500, %{status: 500, message: "Internal Error", detail: reason})
        end

      _ ->
        conn
        |> set_headers()
        |> send_resp(
          400,
          construct_svg(%{
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
          })
        )
    end
  end

  get "/" do
    conn
    |> json_response(400, %{status: 400, message: "Bad Request", detail: "Username not provided"})
  end

  get _ do
    conn
    |> json_response(404, %{
      status: 404,
      message: "Not Found",
      detail: "The requested resource could not be found or does not exist"
    })
  end

  match _ do
    path =
      conn.request_path
      |> case do
        "" -> "/"
        path -> path
      end

    method = conn.method

    conn
    |> json_response(403, %{status: 403, message: "Forbidden", detail: "Cannot #{method} #{path}"})
  end
end
