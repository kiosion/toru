defmodule Toru.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger)

  forward("/api", to: Router.Api)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  @spec json_response(Plug.Conn.t(), atom | 1..1_114_111, any) :: Plug.Conn.t()
  def json_response(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Poison.encode!(body))
  end

  match _ do
    path = conn.request_path
    |> case do
      "" -> "/"
      path -> path
    end
    method = conn.method

    case path |> to_string do
      "/favicon.ico" -> conn |> json_response(404, %{status: 404, message: "The requested resource could not be found or does not exist"})
      _ -> conn |> json_response(403, %{status: 403, message: "Cannot #{method} #{path}"})
    end
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn |> json_response(500, %{status: 500, message: "Sorry, something went wrong"})
  end
end
