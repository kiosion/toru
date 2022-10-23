defmodule ToruTest do
  use ExUnit.Case
  doctest Toru

  test "greets the world" do
    assert Toru.hello() == :world
  end
end
