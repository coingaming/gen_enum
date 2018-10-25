require GenEnum
GenEnum.defenum(Single, :single, [:ONE])

defmodule OS do
  require GenEnum
  GenEnum.defenum(:os, [:LINUX, :MAC, :WINDOWS])
end

defmodule GenEnumTest do
  use ExUnit.Case
  doctest GenEnum

  require OS.Items
  require OS.Meta

  test "EctoEnum" do
    assert OS.EctoEnum.type == :os
  end

  test "Items" do
    assert OS.Items.linux == :LINUX
    assert OS.Items.mac == :MAC
    assert OS.Items.windows == :WINDOWS
  end

  test "Meta.t" do
    defmodule Game do
      require OS.Items

      @spec choose_os(pos_integer) :: OS.Meta.t
      def choose_os(min_fps) when (min_fps <= 30), do: OS.Items.linux
      def choose_os(min_fps) when (min_fps <= 60), do: OS.Items.mac
      def choose_os(_), do: OS.Items.windows
    end

    assert Game.choose_os(1) == :LINUX
    assert Game.choose_os(31) == :MAC
    assert Game.choose_os(61) == :WINDOWS
  end

  test "Meta.database_type" do
    assert OS.Meta.database_type == :os
  end

  test "Meta.values" do
    assert OS.Meta.values == [:LINUX, :MAC, :WINDOWS]
  end

  test "Meta.is_type" do
    assert OS.Meta.is_type :MAC
    assert not OS.Meta.is_type :HELLO
  end

  test "Utils.to_enum" do
    assert {:ok, :MAC} == OS.Utils.to_enum :mac
    assert {:ok, :MAC} == OS.Utils.to_enum "mac"
    assert {:ok, :MAC} == OS.Utils.to_enum "Mac\n"
    assert {
      :error,
      "can not convert value to Elixir.OS, got invalid string from: \"MacOs\""
    } == OS.Utils.to_enum "MacOs"
  end

  test "Utils.to_enum!" do
    assert :MAC == OS.Utils.to_enum! :mac
    assert :MAC == OS.Utils.to_enum! "mac"
    assert :MAC == OS.Utils.to_enum! "Mac\n"
    assert_raise RuntimeError, ~r/can not convert value to Elixir.OS, got invalid string from: \"MacOs\"/, fn ->
      OS.Utils.to_enum! "MacOs"
    end
  end

  test "Utils.values" do
    assert OS.Utils.values == [:LINUX, :MAC, :WINDOWS]
  end

  test "invalid module" do
    assert_raise RuntimeError, "invalid module name \"OS\"", fn ->
      quote do
        require GenEnum
        GenEnum.defenum("OS", :os, [:LINUX, :MAC, :WINDOWS])
      end
      |> Code.eval_quoted
    end
  end

  test "invalid database type" do
    assert_raise RuntimeError, "invalid database type \"os\"", fn ->
      quote do
        require GenEnum
        GenEnum.defenum(OS, "os", [:LINUX, :MAC, :WINDOWS])
      end
      |> Code.eval_quoted
    end
  end

  test "invalid enum values (empty)" do
    assert_raise RuntimeError, "invalid enum values []", fn ->
      quote do
        require GenEnum
        GenEnum.defenum(OS, :os, [])
      end
      |> Code.eval_quoted
    end
  end

  test "invalid enum values" do
    assert_raise RuntimeError, "invalid enum values [\"LINUX\"]", fn ->
      quote do
        require GenEnum
        GenEnum.defenum(OS, :os, ["LINUX", :MAC, :WINDOWS])
      end
      |> Code.eval_quoted
    end
  end
end
