defmodule SqlConvTest do
  use ExUnit.Case
  doctest SqlConv

  test "greets the world" do
    assert SqlConv.hello() == :world
  end
end
