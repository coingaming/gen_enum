defmodule GenEnum do
  @moduledoc """
  Better enumerations support for Elixir and Ecto
  """

  require Uelli

  @doc """
  Macro defines helper modules for better enum support

  - `EctoEnum` definition (if `:database_type` option is provided)
  - `Utils` module with helper functions
  - `Items` module with macro wrapper for each enum value (to not use atoms in source code)
  - `Meta` module with heplful macros (to not use atoms in source code)

  Argument is

  - non empty list of enum values
  - OR keyword list of options
    - `:module` is Elixir module name (for given enum) - can be `nil`/unset
    - `:database_type` is atom (alias for database type for given enum) - can be `nil`/unset
    - `:values` is non empty list of enum values (atoms)

  ## Examples

  ```
  iex> defmodule Os do
  ...>   require GenEnum
  ...>   GenEnum.defenum [:LINUX, :MAC, :WINDOWS]
  ...> end
  iex> quote do
  ...>   require Os.Items
  ...>   Os.Items.linux()
  ...> end
  ...> |> Code.eval_quoted
  {:LINUX, []}

  iex> require GenEnum
  iex> GenEnum.defenum module: Ord, values: [:EQ, :GT, :LT]
  iex> quote do
  ...>   require Ord.Items
  ...>   Ord.Items.eq()
  ...> end
  ...> |> Code.eval_quoted
  {:EQ, []}

  iex> require GenEnum
  iex> GenEnum.defenum module: CurrencyCode, database_type: :currency_code, values: [:USD, :EUR]
  iex> quote do
  ...>   require CurrencyCode.Items
  ...>   CurrencyCode.Items.usd()
  ...> end
  ...> |> Code.eval_quoted
  {:USD, []}
  iex> quote do
  ...>   require CurrencyCode.Meta
  ...>   CurrencyCode.Meta.database_type()
  ...> end
  ...> |> Code.eval_quoted
  {:currency_code, []}
  ```
  """
  defmacro defenum(code) when is_list(code) do
    code
    |> Keyword.keyword?()
    |> case do
      true ->
        opts_ast = {
          :%,
          [],
          [
            {:__aliases__, [alias: false], [:GenEnum, :Opts]},
            {:%{}, [], code}
          ]
        }

        quote do
          GenEnum.defenum(unquote(opts_ast))
        end

      false ->
        quote do
          GenEnum.defenum(%GenEnum.Opts{values: unquote(code)})
        end
    end
  end

  defmacro defenum(code) do
    {
      %GenEnum.Opts{
        module: arg_module,
        database_type: database_type,
        values: values
      } = raw_opts,
      []
    } = Code.eval_quoted(code, [], __CALLER__)

    %Macro.Env{module: caller_module} = __CALLER__

    :ok = validate_modules(arg_module, caller_module)
    :ok = validate_database_type(database_type)
    :ok = validate_values(values)

    full_module = (arg_module && Module.concat(caller_module, arg_module)) || caller_module

    alias_ast =
      if arg_module && caller_module do
        [first_chunk | _] = Module.split(arg_module)

        quote do
          alias unquote(Module.concat(caller_module, first_chunk))
        end
      else
        quote do
        end
      end

    fixed_opts = %GenEnum.Opts{raw_opts | module: full_module}

    #
    # generated code
    #

    quote do
      unquote(define_ecto_enum(fixed_opts))
      unquote(define_enum_items(fixed_opts))
      unquote(define_utils(fixed_opts))
      unquote(define_meta(fixed_opts))
      unquote(alias_ast)
    end
  end

  #
  # priv code generators
  #

  defp define_ecto_enum(%GenEnum.Opts{
         module: module,
         database_type: database_type,
         values: values
       })
       when Uelli.non_nil_atom(module) and Uelli.non_nil_atom(database_type) and is_list(values) do
    quote do
      require EctoEnum

      EctoEnum.defenum(
        unquote(Module.concat(module, "EctoEnum")),
        unquote(database_type),
        unquote(values)
      )
    end
  end

  defp define_ecto_enum(%GenEnum.Opts{
         module: module,
         database_type: nil,
         values: values
       })
       when Uelli.non_nil_atom(module) and is_list(values) do
    quote do
    end
  end

  defp define_enum_items(%GenEnum.Opts{
         module: module,
         values: values
       })
       when Uelli.non_nil_atom(module) and is_list(values) do
    code =
      values
      |> Enum.map(fn v ->
        quote do
          defmacro unquote(v |> Atom.to_string() |> String.downcase() |> String.to_atom())() do
            unquote(v)
          end
        end
      end)

    quote do
      defmodule unquote(Module.concat(module, "Items")) do
        (unquote_splicing(code))
      end
    end
  end

  defp define_utils(%GenEnum.Opts{
         module: module,
         values: values
       })
       when Uelli.non_nil_atom(module) and is_list(values) do
    quote do
      defmodule unquote(Module.concat(module, "Utils")) do
        unquote(define_to_enum(module))
        unquote(define_from_atom_priv(values))
        unquote(define_from_string_priv(values))

        def values do
          unquote(values)
        end
      end
    end
  end

  defp define_meta(%GenEnum.Opts{
         module: module,
         database_type: database_type,
         values: values
       })
       when Uelli.non_nil_atom(module) and is_list(values) do
    database_type_code =
      database_type
      |> case do
        _ when Uelli.non_nil_atom(database_type) ->
          quote do
            defmacro database_type do
              unquote(database_type)
            end
          end

        nil ->
          quote do
          end
      end

    quote do
      defmodule unquote(Module.concat(module, "Meta")) do
        unquote(define_enum_typespec(values))
        unquote(database_type_code)

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
  # low lvl priv code generators
  #

  defp define_to_enum(module) do
    quote do
      @spec to_enum(any) :: {:ok, unquote(module).Meta.t()} | {:error, String.t()}
      def to_enum(value) do
        value
        |> from_atom_priv
        |> case do
          {:ok, result} ->
            {:ok, result}

          :error ->
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
                      {:ok, result} ->
                        {:ok, result}

                      :error ->
                        {:error, "can not convert value to #{unquote(module)}, got invalid string from: #{inspect(value)}"}
                    end

                  false ->
                    {:error, "can not convert value to #{unquote(module)}, got invalid binary from: #{inspect(value)}"}
                end

              ^value ->
                {:error, "can not convert value to #{unquote(module)}, got invalid term: #{inspect(value)}"}
            end
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

  defp define_from_atom_priv(items) do
    code =
      Enum.map(items, fn value ->
        quote do
          defp from_atom_priv(unquote(value)) do
            {:ok, unquote(value)}
          end
        end
      end)
      |> Enum.concat([
        quote do
          defp from_atom_priv(_) do
            :error
          end
        end
      ])

    quote do
      (unquote_splicing(code))
    end
  end

  defp define_from_string_priv(items) do
    code =
      Enum.map(items, fn value ->
        quote do
          defp from_string_priv(unquote(value |> Atom.to_string() |> String.upcase())) do
            {:ok, unquote(value)}
          end
        end
      end)
      |> Enum.concat([
        quote do
          defp from_string_priv(_) do
            :error
          end
        end
      ])

    quote do
      (unquote_splicing(code))
    end
  end

  defp define_enum_typespec([_ | _] = enum_atoms) do
    {:@, [context: Elixir, import: Kernel],
     [
       {:type, [context: Elixir], [{:"::", [], [{:t, [], Elixir}, define_algebraic_type(enum_atoms)]}]}
     ]}
  end

  defp define_algebraic_type([ast_item]) do
    ast_item
  end

  defp define_algebraic_type([_, _] = ast_pair) do
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

  defp validate_modules(nil, nil) do
    raise("GenEnum.defenum/1 macro can be executed only inside the module when :module parameter is not specified")
  end

  defp validate_modules(nil, caller_module) when Uelli.non_nil_atom(caller_module) do
    #
    # TODO : !!!
    #
    :ok
  end

  defp validate_modules(arg_module, nil) when Uelli.non_nil_atom(arg_module) do
    #
    # TODO : !!!
    #
    :ok
  end

  defp validate_modules(arg_module, caller_module)
       when Uelli.non_nil_atom(arg_module) and Uelli.non_nil_atom(caller_module) do
    #
    # TODO : !!!
    #
    :ok
  end

  defp validate_modules(arg_module, _), do: raise("invalid module name #{inspect(arg_module)}")

  defp validate_database_type(atom) when is_atom(atom) do
    #
    # TODO : !!!
    #
    :ok
  end

  defp validate_database_type(some), do: raise("invalid database type #{inspect(some)}")

  defp validate_values(list) when is_list(list) do
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
