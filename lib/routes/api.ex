defmodule Router.Api do
  use Plug.Router
  use Toru.Utils

  forward "/v1", to: Api.V1

  plug :match

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug :dispatch

  match "/v:any" do
    conn |> json_response(400, %{status: 400, message: "Bad Request", detail: "Invalid API version specified"})
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
