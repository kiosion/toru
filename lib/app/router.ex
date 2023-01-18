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

  match _ do
    path = conn.request_path
    |> case do
      "" -> "/"
      path -> path
    end
    method = conn.method

    case path |> to_string do
      "/favicon.ico" -> conn |> json_response(404, %{error: 404, message: "The requested resource could not be found or does not exist"})
      _ -> conn |> json_response(403, %{error: 403, message: "Cannot #{method} #{path}"})
    end
  end

  # Handle errors that have bubbled up to the router unhandled
  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn |> json_response(500, %{error: 500, message: "Sorry, something went wrong"})
  end
end
