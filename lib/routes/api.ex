defmodule Router.Api do
  use Plug.Router
  use Toru.Utils

  # Current API vers
  forward("/v1", to: Api.V1)

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  match "/v:any" do
    conn |> json_response(400, %{error: 400, message: "Invalid API version specified"})
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
