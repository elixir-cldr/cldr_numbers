defmodule Cldr.Number.Backend.Symbol do
  @moduledoc false

  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Number.Symbol do
        unless Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc false
        end

        all_symbols =
          for locale <- Cldr.Locale.Loader.known_locale_names(config) do
            symbols =
              locale
              |> Cldr.Locale.Loader.get_locale(config)
              |> Map.get(:number_symbols)
              |> Enum.map(fn
                {number_system, nil} -> {number_system, nil}
                {number_system, symbols} -> {number_system, struct(Cldr.Number.Symbol, symbols)}
              end)
              |> Enum.into(%{})

            {locale, symbols}
          end
          |> Map.new()

        @doc """
        Returns a map of `Cldr.Number.Symbol.t` structs of the number symbols for each
        of the number systems of a locale.

        ## Options

        * `locale` is any valid locale name returned by
          `#{inspect(backend)}.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by
          `#{inspect(backend)}.Locale.new!/1`. The default
          is `#{inspect(backend)}.get_locale/0`.

        ## Example:

            iex> #{inspect(__MODULE__)}.number_symbols_for(:th)
            {:ok, %{
               latn: %Cldr.Number.Symbol{
                 decimal: ".",
                 exponential: "E",
                 group: ",",
                 infinity: "∞",
                 list: ";",
                 minus_sign: "-",
                 nan: "NaN",
                 per_mille: "‰",
                 percent_sign: "%",
                 plus_sign: "+",
                 superscripting_exponent: "×",
                 time_separator: ":"
               },
               thai: %Cldr.Number.Symbol{
                 decimal: ".",
                 exponential: "E",
                 group: ",",
                 infinity: "∞",
                 list: ";",
                 minus_sign: "-",
                 nan: "NaN",
                 per_mille: "‰",
                 percent_sign: "%",
                 plus_sign: "+",
                 superscripting_exponent: "×",
                 time_separator: ":"
               }
             }}

        """
        @spec number_symbols_for(LanguageTag.t() | Cldr.Locale.locale_name()) ::
                {:ok, map()} | {:error, {module(), String.t()}}

        def number_symbols_for(locale \\ unquote(backend).get_locale())

        for {locale, symbols} <- all_symbols do
          def number_symbols_for(%LanguageTag{cldr_locale_name: unquote(locale)}) do
            {:ok, unquote(Macro.escape(symbols))}
          end
        end

        def number_symbols_for(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            number_symbols_for(locale)
          end
        end

        def number_symbols_for(locale, number_system) do
          with {:ok, system_name} <-
                 unquote(backend).Number.System.system_name_from(number_system, locale),
               {:ok, symbols} <- number_symbols_for(locale) do
            symbols
            |> Map.get(system_name)
            |> Cldr.Number.Symbol.symbols_return(locale, number_system)
          end
        end

        all_decimal_symbols =
          for {_locale, locale_symbols} <- all_symbols,
              {_number_system, symbols} <- locale_symbols,
              !is_nil(symbols) do
            symbols.decimal
          end
          |> Enum.uniq()

        all_grouping_symbols =
          for {_locale, locale_symbols} <- all_symbols,
              {_number_system, symbols} <- locale_symbols,
              !is_nil(symbols) do
            symbols.group
          end
          |> Enum.uniq()

        @doc """
        Returns a list of all decimal symbols defined
        by the locales configured in this backend as
        a list.

        """
        def all_decimal_symbols do
          unquote(Macro.escape(all_decimal_symbols))
        end

        @doc """
        Returns a list of all grouping symbols defined
        by the locales configured in this backend as
        a list.

        """
        def all_grouping_symbols do
          unquote(all_grouping_symbols)
        end

        @doc """
        Returns a list of all decimal symbols defined
        by the locales configured in this backend as
        a string.

        This string can be used as a character class
        when builing a regular expression.

        """
        def all_decimal_symbols_class do
          unquote(all_decimal_symbols)
        end

        @doc """
        Returns a list of all grouping symbols defined
        by the locales configured in this backend as
        a string.

        This string can be used as a character class
        when builing a regular expression.

        """
        def all_grouping_symbols_class do
          unquote(Enum.join(all_grouping_symbols))
        end
      end
    end
  end
end
