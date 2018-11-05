defmodule Cldr.Number.Backend.Decimal.Formatter do
  def define_number_module(config) do
    alias Cldr.Number.Formatter.Decimal

    backend = config.backend

    quote location: :keep do
      defmodule Number.Formatter.Decimal do
        @moduledoc false

        @doc """
        Formats a number according to a decimal format string.

        ## Arguments

        * `number` is an integer, float or Decimal

        * `format` is a format string.  See `Cldr.Number` for further information.

        * `options` is a map of options.  See `Cldr.Number.to_string/2` for further information.

        """
        alias Cldr.Number.Format.Compiler
        alias Cldr.Number.Formatter.Decimal

        @spec to_string(Math.number(), String.t(), Map.t()) ::
                {:ok, String.t()} | {:error, {atom, String.t()}}
        def to_string(number, format, options)

        # Precompile the known formats and build the formatting pipeline
        # specific to this format thereby optimizing the performance.
        unquote(Decimal.define_to_string(backend))

        # For formats not precompiled we need to compile first
        # and then process. This will be slower than a compiled
        # format since we have to (a) compile the format and (b)
        # execute the full formatting pipeline.
        def to_string(number, format, options) when is_map(options) do
          case Compiler.compile(format) do
            {:ok, meta, _pipeline} ->
              meta = Decimal.update_meta(meta, number, unquote(backend), options)
              Decimal.do_to_string(number, meta, unquote(backend), options)

            {:error, message} ->
              {:error, {Cldr.FormatCompileError, message}}
          end
        end
      end
    end
  end
end