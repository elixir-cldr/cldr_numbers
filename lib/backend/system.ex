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

        * `locale` is any valid locale name returned by `#{inspect(backend)}.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `#{inspect(backend)}.Locale.new!/1`

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

        @doc """
        Returns the number systems available for a locale
        or `{:error, message}` if the locale is not known.

        * `locale` is any valid locale name returned by `#{inspect(backend)}.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `#{inspect(backend)}.Locale.new!/1`

        ## Examples

            iex> #{inspect(__MODULE__)}.number_system_names_for Cldr.Locale.new!("en")
            {:ok, [:latn]}

            iex> #{inspect(__MODULE__)}.number_system_names_for Cldr.Locale.new!("zz")
            {:error, {Cldr.UnknownLocaleError, "The locale \\"zz\\" is not known."}}

        """
        @spec number_system_names_for(Locale.name() | LanguageTag.t()) :: list(atom())
        def number_system_names_for(locale)

        for locale_name <- Cldr.Config.known_locale_names(config) do
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

          def number_system_names_for(unquote(locale_name)) do
            with {:ok, systems} <- number_systems_for(unquote(locale_name)) do
              {:ok, Map.values(systems) |> Enum.uniq()}
            end
          end

          def number_system_names_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
            number_system_names_for(unquote(locale_name))
          end

          def number_system_types_for(unquote(locale_name)) do
            with {:ok, systems} <- number_systems_for(unquote(locale_name)) do
              {:ok, Map.keys(systems) |> Enum.uniq()}
            end
          end

          def number_system_types_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
            number_system_types_for(unquote(locale_name))
          end
        end

        def number_systems_for(locale) do
          {:error, Cldr.Locale.locale_error(locale)}
        end

        def number_system_names_for(locale) do
          {:error, Cldr.Locale.locale_error(locale)}
        end

        def number_system_types_for(locale) do
          {:error, Cldr.Locale.locale_error(locale)}
        end
      end
    end
  end
end
