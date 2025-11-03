defmodule HackatonTest do
  use ExUnit.Case
  doctest Hackaton

  test "greets the world" do
    assert Hackaton.hello() == :world
  end
end
