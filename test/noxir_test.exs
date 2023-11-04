defmodule NoxirTest do
  use ExUnit.Case
  doctest Noxir

  test "greets the world" do
    assert Noxir.hello() == :world
  end
end
