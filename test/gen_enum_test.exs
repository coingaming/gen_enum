require GenEnum
GenEnum.defenum(Single, :single, [:ONE])

require GenEnum
GenEnum.defenum(MyMod1.OS, :os, [:LINUX, :MAC, :WINDOWS])

defmodule MyMod2.OS do
  require GenEnum
  GenEnum.defenum(:os, [:LINUX, :MAC, :WINDOWS])
end

defmodule MyMod3 do
  require GenEnum
  GenEnum.defenum(OS, :os, [:LINUX, :MAC, :WINDOWS])
end

defmodule GenEnumTest do
  use ExUnit.Case
  doctest GenEnum

  [MyMod1, MyMod2, MyMod3]
  |> Enum.each(fn module ->

    test "#{module} EctoEnum" do
      alias unquote(module).OS
      assert OS.EctoEnum.type == :os
    end

    test "#{module} Items" do
      alias unquote(module).OS
      require OS.Items
      assert OS.Items.linux == :LINUX
      assert OS.Items.mac == :MAC
      assert OS.Items.windows == :WINDOWS
    end

    test "#{module} Meta.t" do
      defmodule unquote(Module.concat(module, "Game")) do
        alias unquote(module).OS
        require OS.Items

        @spec choose_os(pos_integer) :: OS.Meta.t
        def choose_os(min_fps) when (min_fps <= 30), do: OS.Items.linux
        def choose_os(min_fps) when (min_fps <= 60), do: OS.Items.mac
        def choose_os(_), do: OS.Items.windows
      end

      alias unquote(Module.concat(module, "Game"))
      assert Game.choose_os(1) == :LINUX
      assert Game.choose_os(31) == :MAC
      assert Game.choose_os(61) == :WINDOWS
    end

    test "#{module} Meta.database_type" do
      alias unquote(module).OS
      require OS.Meta
      assert OS.Meta.database_type == :os
    end

    test "#{module} Meta.values" do
      alias unquote(module).OS
      require OS.Meta
      assert OS.Meta.values == [:LINUX, :MAC, :WINDOWS]
    end

    test "#{module} Meta.is_type" do
      alias unquote(module).OS
      require OS.Meta
      assert OS.Meta.is_type :MAC
      assert not OS.Meta.is_type :HELLO
    end

    test "#{module} Utils.to_enum" do
      alias unquote(module).OS
      assert {:ok, :MAC} == OS.Utils.to_enum :mac
      assert {:ok, :MAC} == OS.Utils.to_enum "mac"
      assert {:ok, :MAC} == OS.Utils.to_enum "Mac\n"
      assert {
        :error,
        "can not convert value to #{unquote(module)}.OS, got invalid string from: \"MacOs\""
      } == OS.Utils.to_enum "MacOs"
    end

    test "#{module} Utils.to_enum!" do
      alias unquote(module).OS
      assert :MAC == OS.Utils.to_enum! :mac
      assert :MAC == OS.Utils.to_enum! "mac"
      assert :MAC == OS.Utils.to_enum! "Mac\n"
      assert_raise RuntimeError, ~r/can not convert value to #{unquote(module)}.OS, got invalid string from: \"MacOs\"/, fn ->
        OS.Utils.to_enum! "MacOs"
      end
    end

    test "#{module} Utils.values" do
      alias unquote(module).OS
      assert OS.Utils.values == [:LINUX, :MAC, :WINDOWS]
    end

    test "#{module} invalid module" do
      alias unquote(module).OS
      assert_raise RuntimeError, "invalid module name \"OS\"", fn ->
        quote do
          require GenEnum
          GenEnum.defenum("OS", :os, [:LINUX, :MAC, :WINDOWS])
        end
        |> Code.eval_quoted
      end
    end

    test "#{module} invalid database type" do
      alias unquote(module).OS
      assert_raise RuntimeError, "invalid database type \"os\"", fn ->
        quote do
          require GenEnum
          GenEnum.defenum(OS, "os", [:LINUX, :MAC, :WINDOWS])
        end
        |> Code.eval_quoted
      end
    end

    test "#{module} invalid enum values (empty)" do
      alias unquote(module).OS
      assert_raise RuntimeError, "invalid enum values []", fn ->
        quote do
          require GenEnum
          GenEnum.defenum(OS, :os, [])
        end
        |> Code.eval_quoted
      end
    end

    test "#{module} invalid enum values" do
      alias unquote(module).OS
      assert_raise RuntimeError, "invalid enum values [\"LINUX\"]", fn ->
        quote do
          require GenEnum
          GenEnum.defenum(OS, :os, ["LINUX", :MAC, :WINDOWS])
        end
        |> Code.eval_quoted
      end
    end
  end)
end
