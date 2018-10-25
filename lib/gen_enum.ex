defmodule GenEnum do
  @moduledoc """
  Better enumerations support for Elixir and Ecto
  """

  @doc """
  Macro defines helper modules for better enum support

  - `EctoEnum` definition
  - `Utils` module with helper functions
  - `Items` module with macro wrapper for each enum value (to not use atoms in source code)
  - `Meta` module with heplful macros (to not use atoms in source code)

  Arguments are the same as in `EctoEnum` defenum macro
  """

  defmacro defenum(quoted_database_type, quoted_values) do
    quote do
      GenEnum.defenum(nil, unquote(quoted_database_type), unquote(quoted_values))
    end
  end

  defmacro defenum(quoted_module, quoted_database_type, quoted_values) do
    %Macro.Env{module: caller_module} = __CALLER__

    {module, []} = Code.eval_quoted(quoted_module, [], __CALLER__)
    full_module = quoted_module && Module.concat(caller_module, module) || caller_module
    {database_type, []} = Code.eval_quoted(quoted_database_type, [], __CALLER__)
    {values, []} = Code.eval_quoted(quoted_values, [], __CALLER__)

    :ok = validate_module(module)
    :ok = validate_database_type(database_type)
    :ok = validate_values(values)

    #
    # generated code
    #

    quote do
      require EctoEnum

      EctoEnum.defenum(
        unquote(concat_module([full_module, module, "EctoEnum"])),
        unquote(database_type),
        unquote(values)
      )

      defmodule unquote(concat_module([full_module, module, "Items"])) do
        unquote(define_enum_items(values))
      end

      defmodule unquote(concat_module([full_module, module, "Utils"])) do
        unquote(define_to_enum(full_module))
        unquote(define_from_string_priv(values))

        def values do
          unquote(values)
        end
      end

      defmodule unquote(concat_module([full_module, module, "Meta"])) do
        unquote(define_enum_typespec(values))

        defmacro database_type do
          unquote(database_type)
        end

        defmacro values do
          unquote(values)
        end

        defmacro is_type(expression) do
          inner_values = unquote(values)

          quote do
            unquote(expression) in unquote(inner_values)
          end
        end
      end
    end
  end

  #
  # priv code generators
  #

  defp concat_module(modules) do
    modules
    |> Enum.reject(&!&1)
    |> Module.concat()
  end

  defp define_to_enum(module) do
    quote do
      @spec to_enum(any) :: {:ok, unquote(module).Meta.t()} | {:error, String.t()}
      def to_enum(value) do
        value
        |> Aspire.to_string()
        |> case do
          bin when is_binary(bin) ->
            bin
            |> String.valid?()
            |> case do
              true ->
                bin
                |> String.trim()
                |> String.upcase()
                |> from_string_priv
                |> case do
                  :error ->
                    {:error, "can not convert value to #{unquote(module)}, got invalid string from: #{inspect(value)}"}

                  {:ok, result} ->
                    {:ok, result}
                end

              false ->
                {:error, "can not convert value to #{unquote(module)}, got invalid binary from: #{inspect(value)}"}
            end

          ^value ->
            {:error, "can not convert value to #{unquote(module)}, got invalid term: #{inspect(value)}"}
        end
      end

      @spec to_enum!(any) :: unquote(module).Meta.t() | no_return
      def to_enum!(value) do
        value
        |> to_enum
        |> case do
          {:ok, result} -> result
          {:error, error} -> raise(error)
        end
      end
    end
  end

  defp define_from_string_priv(items) do
    items
    |> Enum.reduce(
      quote do
        defp from_string_priv(value) do
          :error
        end
      end,
      fn value, acc ->
        quote do
          defp from_string_priv(unquote(value |> Atom.to_string())) do
            {:ok, unquote(value)}
          end

          unquote(acc)
        end
      end
    )
  end

  defp define_enum_items(items) do
    items
    |> Enum.reduce(
      quote do
      end,
      fn enum_item, acc ->
        quote do
          unquote(acc)

          defmacro unquote(enum_item |> Atom.to_string() |> String.downcase() |> String.to_atom())() do
            unquote(enum_item)
          end
        end
      end
    )
  end

  defp define_enum_typespec(enum_atoms) do
    {:@, [context: Elixir, import: Kernel],
     [
       {:type, [context: Elixir], [{:::, [], [{:t, [], Elixir}, define_algebraic_type(enum_atoms)]}]}
     ]}
  end

  defp define_algebraic_type([ast_item]) do
    ast_item
  end

  defp define_algebraic_type(ast_pair = [_, _]) do
    {
      :|,
      [],
      ast_pair
    }
  end

  defp define_algebraic_type([ast_item | rest_ast_list]) do
    {
      :|,
      [],
      [
        ast_item,
        define_algebraic_type(rest_ast_list)
      ]
    }
  end

  #
  # priv validators
  #

  defp validate_module(atom) when is_atom(atom) do
    #
    # TODO : !!!
    #
    :ok
  end

  defp validate_module(some), do: raise("invalid module name #{inspect(some)}")

  defp validate_database_type(atom) when is_atom(atom) and atom != nil do
    #
    # TODO : !!!
    #
    :ok
  end

  defp validate_database_type(some), do: raise("invalid database type #{inspect(some)}")

  defp validate_values(list = [_ | _]) do
    #
    # TODO
    #
    list
    |> Enum.filter(&(not (is_atom(&1) and &1 != nil)))
    |> case do
      [] -> :ok
      invalid_values = [_ | _] -> raise("invalid enum values #{inspect(invalid_values)}")
    end
  end

  defp validate_values(some), do: raise("invalid enum values #{inspect(some)}")
end
