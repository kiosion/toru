defmodule Toru.Router do
  use Plug.Router
  use Plug.ErrorHandler
  use Toru.Utils

  plug(Plug.Logger)

  forward("/api", to: Router.Api)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  match "/info" do
    version = app_version()
    elixir = to_string(System.version())
    otp = to_string(:erlang.system_info(:otp_release))

    conn |> json_response(200, %{status: 200, data: %{version: version, elixir: elixir, otp: otp}})
  end

  match _ do
    path = conn.request_path
    |> case do
      "" -> "/"
      path -> path
    end
    method = conn.method

    case path |> to_string do
      "/favicon.ico" -> conn |> json_response(404, %{status: 404, message: "Not Found", detail: "The requested resource could not be found or does not exist"})
      _ -> conn |> json_response(403, %{status: 403, message: "Forbidden", detail: "Cannot #{method} #{path}"})
    end
  end

  # Handle errors that have bubbled up to the router unhandled
  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn |> json_response(500, %{status: 500, message: "Internal Error", detail: "Sorry, something went wrong"})
  end
end
