# GenEnum

[![Hex](https://raw.githubusercontent.com/tim2CF/static-asserts/master/build-passing.svg?sanitize=true)](https://hex.pm/packages/coingaming/gen_enum/)
[![Documentation](https://raw.githubusercontent.com/tim2CF/static-asserts/master/documentation-passing.svg?sanitize=true)](https://coingaming.hexdocs.pm/gen_enum/)

<img src="priv/gen_enum_logo.png" width="300"/>

Enumerations are common abstraction to express the limited set of values. In Elixir language enumeration values are usually expressed as atoms. **&GenEnum.defenum/1** macro generates compile/runtime utilities for given enumeration. Argument is

- non empty list of enum values (atoms), example: **[:LINUX, :MAC, :WINDOWS]**
- **OR** keyword list of options
  - `:module` is Elixir module name (main module of enumeration definition) - can be `nil`/unset, example: **OS**
  - `:database_type` is atom (alias for database type for given enum) - can be `nil`/unset, example: **:os**
  - `:values` is non empty list of enum values (atoms), example: **[:LINUX, :MAC, :WINDOWS]**

## Installation

The package can be installed
by adding `gen_enum` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_enum, "~> 0.3"}
  ]
end
```

## Example

Let's use **&GenEnum.defenum/1** macro and generate **OS** enumeration:

```elixir
require GenEnum
GenEnum.defenum(module: OS, database_type: :os, values: [:LINUX, :MAC, :WINDOWS])
```
Under **OS** module namespace this expression generates 4 additional modules:

### 1) OS.EctoEnum

Module contains standard [EctoEnum](https://github.com/gjaldon/ecto_enum) definition of given enumeration. Can be used for Ecto integration and database migrations (read EctoEnum manual). If `:database_type` is `nil`/unset then this module will not be generated.

### 2) OS.Items

Module contains **macro** wrappers for the every value of given enum. It's recommended to use macro wrappers instead of the atom literals to avoid runtime errors (for example, after refactoring)

```elixir
iex> require OS.Items
OS.Items

iex> OS.Items.linux
:LINUX

iex> OS.Items.mac
:MAC
```

### 3) OS.Meta

Module contains **@type t** definition for enumeration and **macro** helpers for guards, Ecto migrations and any other places where those macros are useful

```elixir
iex> require OS.Meta
OS.Meta
```

  - **OS.Meta.t** definition is useful for **@type** and **@specs** notations

  ```elixir
  defmodule Game do
      require OS.Items

      @spec choose_os(pos_integer) :: OS.Meta.t
      def choose_os(min_fps) when (min_fps <= 30), do: OS.Items.linux
      def choose_os(min_fps) when (min_fps <= 60), do: OS.Items.mac
      def choose_os(_), do: OS.Items.windows
  end
  ```

  - **database_type** macro wrapper for database type of enum in Ecto migrations. If `:database_type` argument is `nil`/unset then this macro will not be generated.

  ```elixir
  iex> OS.Meta.database_type
  :os
  ```

  - **values** list of all possible enumeration values

  ```elixir
  iex> OS.Meta.values
  [:LINUX, :MAC, :WINDOWS]
  ```

  - **is_type** useful macro for guard expressions

  ```elixir
  iex> OS.Meta.is_type OS.Items.mac
  true

  iex> OS.Meta.is_type :HELLO
  false
  ```

### 4) OS.Utils

Module contains some helper **functions**

  - **to_enum** and **to_enum!** are polymorphic functions to convert term into enumeration value (if it is possible)

  ```elixir
  iex> OS.Utils.to_enum :mac
  {:ok, :MAC}
  iex> OS.Utils.to_enum "mac"
  {:ok, :MAC}
  iex> OS.Utils.to_enum "Mac\n"
  {:ok, :MAC}
  iex> OS.Utils.to_enum "MacOs"
  {:error, "can not convert value to Elixir.OS, got invalid string from: \"MacOs\""}

  iex> OS.Utils.to_enum! :mac
  :MAC
  iex> OS.Utils.to_enum! "mac"
  :MAC
  iex> OS.Utils.to_enum! "Mac\n"
  :MAC
  iex> OS.Utils.to_enum! "MacOs"
  ** (RuntimeError) can not convert value to Elixir.OS, got invalid string from: "MacOs"
      iex:4: OS.Utils.to_enum!/1

  iex> OS.Utils.values
  [:LINUX, :MAC, :WINDOWS]
  ```
