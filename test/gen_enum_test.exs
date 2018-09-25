defmodule GenEnumTest do
  use ExUnit.Case
  doctest GenEnum

  test "greets the world" do
    assert GenEnum.hello() == :world
  end
end
