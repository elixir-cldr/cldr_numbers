defmodule Cldr.Number.Backend.Symbol do
  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Number.Symbol do
        @doc """
        Returns a map of `Cldr.Number.Symbol.t` structs of the number symbols for each
        of the number systems of a locale.

        ## Options

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`.  The
          default is `Cldr.get_current_locale/0`.

        ## Example:

            iex> #{inspect(__MODULE__)}.number_symbols_for("th")
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
        @spec number_symbols_for(LanguageTag.t() | Locale.locale_name()) :: Keyword.t()
        def number_symbols_for(locale \\ unquote(backend).get_current_locale())

        for locale <- Cldr.Config.known_locale_names(config) do
          symbols =
            locale
            |> Cldr.Config.get_locale()
            |> Map.get(:number_symbols)
            |> Enum.map(fn
              {k, nil} -> {k, nil}
              {k, v} -> {k, struct(Cldr.Number.Symbol, v)}
            end)
            |> Enum.into(%{})

          def number_symbols_for(%LanguageTag{cldr_locale_name: unquote(locale)}) do
            {:ok, unquote(Macro.escape(symbols))}
          end
        end

        def number_symbols_for(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            number_symbols_for(locale)
          end
        end

        def number_symbols_for(locale) do
          {:error, Cldr.Locale.locale_error(locale)}
        end
      end
    end
  end
end