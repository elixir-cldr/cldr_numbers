defmodule Cldr.Number.Backend.Decimal.Formatter do
  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
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
        for format <- Number.Format.decimal_format_list() do
          case Compiler.compile(format) do
            {:ok, meta, formatting_pipeline} ->
              def to_string(number, unquote(format), options) when is_map(options) do
                meta = Decimal.update_meta(unquote(Macro.escape(meta)), number, unquote(backend), options)
                unquote(formatting_pipeline)
              end

            {:error, message} ->
              raise Cldr.FormatCompileError, "#{message} compiling #{inspect(format)}"
          end
        end

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