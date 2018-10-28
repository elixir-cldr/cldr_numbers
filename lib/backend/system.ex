defmodule Cldr.Number.Backend.System do
  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Number.System do
        @doc """
        Returns the number systems available for a locale
        or `{:error, message}` if the locale is not known.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

        ## Examples

            iex> #{inspect(__MODULE__)}.number_systems_for Cldr.Locale.new!("en")
            {:ok, %{default: :latn, native: :latn}}

            iex> #{inspect(__MODULE__)}.number_systems_for Cldr.Locale.new!("th")
            {:ok, %{default: :latn, native: :thai}}

            iex> #{inspect(__MODULE__)}.number_systems_for Cldr.Locale.new!("zz")
            {:error, {Cldr.UnknownLocaleError, "The locale \\"zz\\" is not known."}}

        """
        @spec number_systems_for(Locale.name() | LanguageTag.t()) :: Map.t()
        def number_systems_for(locale)

        for locale_name <- Cldr.Config.known_locale_names(backend) do
          systems =
            locale_name
            |> Cldr.Config.get_locale()
            |> Map.get(:number_systems)

          def number_systems_for(unquote(locale_name)) do
            {:ok, unquote(Macro.escape(systems))}
          end

          def number_systems_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
            number_systems_for(unquote(locale_name))
          end
        end

        def number_systems_for(locale) do
          {:error, Locale.locale_error(locale)}
        end
      end
    end
  end
end