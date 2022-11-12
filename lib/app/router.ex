defmodule Toru.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger)

  forward("/api", to: Toru.Router.Api)

  plug(:match)

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

  get "/" do
    json_response(conn, 403, %{status: 403, message: "Cannot GET /"})
  end

  match _ do
    json_response(conn, 404, %{status: 404, message: "Requested resource or route could not be found"})
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    json_response(conn, 500, %{status: 500, message: "Sorry, something went wrong"})
  end
end
