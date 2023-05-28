defmodule ToruApplicationTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Toru.Application

  @opts Toru.Router.init([])

  test "GET /" do
    conn = conn(:get, "/")
      |> Toru.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 403 # Shouldn't be able to GET non-api routes

    body = Poison.decode! conn.resp_body

    assert body["message"] == "Forbidden"
  end

  defp assert_same_type expected, actual do
    case expected do
      _ when is_map expected ->
        Enum.each(expected, fn {key, value} ->
          assert_same_type value, actual[key]
        end)

      _ ->
        assert is_map(actual) == is_map(expected)
        assert is_integer(actual) == is_integer(expected)
        assert is_boolean(actual) == is_boolean(expected)
        assert is_binary(actual) == is_binary(expected)
    end
  end

  test "GET json res from API" do
    conn = conn(:get, "/api/v1/kiosion?res=json")
      |> Toru.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    expected = %{
      "status" => 0,
      "data" => %{
        "title" => "",
        "artist" => "",
        "album" => "",
        "playing" => false,
        "streamable" => false,
        "cover_art" => %{
          "data" => "",
          "mime_type" => "",
        },
      },
    }

    body = Poison.decode! conn.resp_body

    Enum.each(expected, fn {key, value} ->
      assert_same_type value, body[key]
    end)
  end
end
