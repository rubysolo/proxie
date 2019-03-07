defmodule ProxieTest do
  use ExUnit.Case
  doctest Proxie

  test "greets the world" do
    assert Proxie.hello() == :world
  end
end
