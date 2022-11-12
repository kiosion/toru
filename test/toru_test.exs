defmodule ToruTest do
  use ExUnit.Case
  doctest Toru
  doctest Toru.Application

  test "greets the world" do
    assert Toru.hello() == :world
  end

  test "filler test to make sure the test suite runs" do
    assert true
  end
end
