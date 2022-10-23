defmodule Toru.Router.Api do
  use Plug.Router
  use Plug.ErrorHandler

  forward("/v1", to: Toru.Router.Api.V1)

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

  match "/v:any" do
    json_response(conn, 400, %{status: 400, message: "Invalid version specified"})
  end

  match _ do
    json_response(conn, 400, %{status: 400, message: "No version specified"})
  end
end
