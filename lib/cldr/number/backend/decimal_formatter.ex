defmodule Cldr.Number.Backend.Decimal.Formatter do
  @moduledoc false

  def define_number_module(config) do
    alias Cldr.Number.Formatter.Decimal

    backend = config.backend

    quote location: :keep do
      defmodule Number.Formatter.Decimal do
        unless Cldr.Config.include_module_docs?(unquote(config.generate_docs)) do
          @moduledoc false
        end

        alias Cldr.Number.Formatter.Decimal
        alias Cldr.Number.Format.Compiler
        alias Cldr.Number.Format.Meta
        alias Cldr.Number.Format.Options
        alias Cldr.Math

        @doc """
        Formats a number according to a decimal format string.

        ## Arguments

        * `number` is an integer, float or Decimal

        * `format` is a format string.  See `#{inspect(unquote(backend))}.Number` for further information.

        * `options` is a map of options.  See `#{inspect(unquote(backend))}.Number.to_string/2`
          for further information.

        """

        @spec to_string(
                Math.number_or_decimal(),
                String.t() | Meta.t(),
                Keyword.t() | Options.t()
              ) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}

        def to_string(number, format, options \\ [])

        def to_string(number, format, options) when is_binary(format) and is_list(options) do
          with {:ok, options} <- Options.validate_options(number, unquote(backend), options) do
            to_string(number, format, options)
          end
        end

        # Precompile the known formats and build the formatting pipeline
        # specific to this format thereby optimizing the performance.
        unquote(Decimal.define_to_string(backend))

        # Other number formatting systems may create the formatting
        # metadata by other means (like a printf function) in which
        # case we don't do anything except format
        def to_string(number, %Meta{} = meta, %Options{} = options) do
          meta = Decimal.update_meta(meta, number, unquote(backend), options)
          Decimal.do_to_string(number, meta, unquote(backend), options)
        end

        def to_string(number, %Meta{} = meta, options) do
          with {:ok, options} <- Options.validate_options(number, unquote(backend), options) do
            to_string(number, meta, options)
          end
        end

        # For formats not precompiled we need to compile first
        # and then process. This will be slower than a compiled
        # format since we have to (a) compile the format and (b)
        # execute the full formatting pipeline.
        require Compiler

        def to_string(number, format, %Options{} = options) when is_binary(format) do
          Compiler.maybe_log_compile_warning(format, unquote(config),
            "ex_cldr_numbers: number format #{inspect format} is being compiled. " <>
            "For performance reasons please consider adding this format to the " <>
            "`precompile_number_formats` list in the backend configuration.")

          case Compiler.format_to_metadata(format) do
            {:ok, meta} ->
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
