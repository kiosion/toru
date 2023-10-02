defmodule Api.V1 do
  use Plug.Router
  use Toru.Assets
  use Toru.Utils
  use Toru.Cache

  require Logger

  plug(:match)

  plug(:fetch_query_params)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  @themes get_asset(:themes)

  @default_params %{
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
      :title => params.title,
      :artist => params.artist,
      :album => params.album,
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
      cond do
        params.blur != nil ->
          Map.put(
            values,
            :background_image,
            get_asset(:background_image) |> replace_in_string!(values)
          )

        true ->
          Map.put(values, :background_image, "")
      end

    get_asset(:base_svg)
    |> replace_in_string!(values)
    |> String.trim()
    |> String.replace("\r", "")
    |> String.replace(~r{>\s+<}, "><")
  end

  @spec fetch_cover_art(String.t()) :: binary()
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
              |> Enum.find(fn {k, _} -> k == "Content-Type" or k == "content-type" end)
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
  defp set_headers(conn),
    do:
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

  @spec start_cover_art_task(map(), map()) :: Task.t()
  defp start_cover_art_task(params, recent_track) do
    Task.async(fn ->
      req_size =
        if params != nil and params != %{} do
          case params.cover_size do
            "large" -> "extralarge"
            "medium" -> "large"
            "small" -> "medium"
            _ -> "large"
          end
        else
          "medium"
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

  @spec determine_nowplaying(map()) :: boolean()
  defp determine_nowplaying(recent_track) do
    recent_track
    |> Map.get("@attr", %{})
    |> Map.get("nowplaying", "false")
    |> (fn status -> status == "true" or status == true end).()
  end

  @spec determine_svg_url(map()) :: binary | nil
  defp determine_svg_url(%{svg_url: svg_url}), do: svg_url
  defp determine_svg_url(%{url: url}), do: url
  defp determine_svg_url(_params), do: nil

  @spec validate_svg_content(map(), binary()) :: String.t() | {:error, {integer(), String.t()}}
  defp validate_svg_content(headers, body) do
    headers
    |> Enum.find(fn {k, _} -> k == "Content-Type" or k == "content-type" end)
    |> case do
      {_, v} when v in ["image/svg+xml", "image/svg"] -> body
      _ -> {:error, {415, "Provided SVG resource is not of type image/svg+xml"}}
    end
  end

  @spec fetch_and_validate_custom_svg(binary()) :: String.t() | {:error, {integer(), String.t()}}
  defp fetch_and_validate_custom_svg(svgUrl) when is_binary(svgUrl) do
    try do
      with {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} <-
             Application.get_env(:toru, :http_client, Toru.DefaultHTTPClient).get(svgUrl) do
        validate_svg_content(headers, body)
      else
        _ -> {:error, {500, "Failed to fetch SVG resource"}}
      end
    rescue
      _ -> {:error, {500, "Failed to fetch SVG resource"}}
    end
  end

  defp fetch_and_validate_custom_svg(_), do: nil

  @spec encode_svg_values(map()) :: map()
  defp encode_svg_values(recent_track) do
    html_encode(%{
      :title => recent_track["name"],
      :artist => recent_track["artist"]["#text"],
      :album => recent_track["album"]["#text"]
    })
  end

  @spec get_svg(
          nil,
          boolean(),
          Task.t(),
          map(),
          map()
        ) :: {:ok, String.t()}
  defp get_svg(nil, nowplaying, values, cover_art, params) do
    %{data: cover_art_data, mime_type: cover_art_mime_type} = Task.await(cover_art)

    {
      :ok,
      construct_svg(%{
        :title => values.title,
        :artist => values.artist,
        :album => values.album,
        :playing => nowplaying,
        :cover_art => cover_art_data,
        :mime_type => cover_art_mime_type,
        :theme => params.theme,
        :art_radius => params.album_radius,
        :border_radius => params.border_radius,
        :border_width => params.border_width,
        :blur => params.blur
      })
    }
  end

  @spec get_svg(
          {:error, {integer(), String.t()}},
          boolean(),
          Task.t(),
          map(),
          map()
        ) :: {:error, {integer(), String.t()}}
  defp get_svg({:error, _} = error, _, _, _, _), do: error

  @spec get_svg(
          String.t(),
          boolean(),
          Task.t(),
          map(),
          map()
        ) :: {:ok, String.t()}
  defp get_svg(svg, _nowplaying, values, cover_art, _params) when is_binary(svg) do
    %{data: cover_art_data, mime_type: cover_art_mime_type} = Task.await(cover_art)

    {
      :ok,
      replace_in_string!(
        svg,
        %{
          :title => values.title,
          :artist => values.artist,
          :album => values.album,
          :cover_art => "data:#{cover_art_mime_type};base64,#{cover_art_data}",
          :image => "data:#{cover_art_mime_type};base64,#{cover_art_data}"
        },
        ~r/\${(.*?)}/u
      )
    }
  end

  @spec get_json(map(), nil | maybe_improper_list | map()) :: map()
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

  @spec handle_res_type(Plug.Conn.t(), binary(), map(), nil | maybe_improper_list() | map()) ::
          Plug.Conn.t()
  defp handle_res_type(conn, "json", params, recent_track) do
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
  end

  @spec handle_res_type(Plug.Conn.t(), binary(), map(), nil | maybe_improper_list() | map()) ::
          Plug.Conn.t()
  defp handle_res_type(conn, _type, params, recent_track) do
    case determine_svg_url(params)
         |> fetch_and_validate_custom_svg()
         |> get_svg(
           determine_nowplaying(recent_track),
           encode_svg_values(recent_track),
           start_cover_art_task(params, recent_track),
           params
         ) do
      {:ok, svg} ->
        conn |> set_headers() |> send_resp(200, svg)

      {:error, {code, msg}} ->
        Logger.error("Error generating SVG: #{inspect({code, msg})}")

        conn
        |> json_response(code, %{status: code, message: msg})
    end
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
    with params <-
           fetch_query_params(conn).query_params |> validate_query_params(@default_params),
         # TODO: This fetch should be batched with the one for fetching custom svg asset and passed to
         # handle_res_type as a Task (if applicable)
         {:ok, res} <- fetch_res(lfm_url!(username)),
         [recent_track | _] <- res |> Map.get("recenttracks", []) |> Map.get("track", []) do
      conn |> handle_res_type(params.res, params, recent_track)
    else
      {:error, res} ->
        Logger.notice("Error: #{res.reason}")

        case res.code do
          404 ->
            conn
            |> json_response(404, %{
              status: 404,
              message: "Not found",
              detail: "Specified user '#{html_encode(username)}' does not exist or is private"
            })

          _ ->
            conn
            |> json_response(500, %{status: 500, message: "Internal Error", detail: res.reason})
        end

      _ ->
        conn
        |> json_response(400, %{
          status: 400,
          message: "Bad Request",
          detail: "No recent tracks found"
        })
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
