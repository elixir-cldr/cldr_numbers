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

        @doc """
        Converts a number into the representation of
        a non-latin number system.

        This function converts numbers to a known
        number system only, it does not provide number
        formatting.

        * `number` is a `float`, `integer` or `Decimal`

        * `system_name` is any number system name returned by
          `Cldr.known_number_systems/0` or a number system type
          returned by `Cldr.known_number_system_types/0`

        There are two types of number systems in CLDR:

        * `:numeric` in which the number system defines
          a direct mapping between the latin digits `0..9`
          into a the number system equivalent.  In this case,
        ` to_system/2` invokes `Cldr.Number.Transliterate.transliterate_digits/3`
          for the given number.

        * `:algorithmic` in which the number system
          does not have the same structure as the `:latn`
          number system and therefore the conversion is
          done algorithmically.  For CLDR the algorithm
          is implemented through `Cldr.Rbnf` rulesets.
          These rulesets are considered by CLDR to be
          less rigorous than the `:numeric` number systems
          and caution and testing for a specific use case
          is recommended.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_system 123456, :hebr
            {:ok, "ק׳׳ת׳"}

            iex> #{inspect(__MODULE__)}.to_system 123, :hans
            {:ok, "一百二十三"}

            iex> #{inspect(__MODULE__)}.to_system 123, :hant
            {:ok, "一百二十三"}

            iex> #{inspect(__MODULE__)}.to_system 123, :hansfin
            {:ok, "壹佰贰拾叁"}

        """
        for {system, definition} <- Cldr.Config.number_systems() do
          if definition.type == :numeric do
            def to_system(number, unquote(system)) do
              string =
                number
                |> to_string
                |> Cldr.Number.Transliterate.transliterate_digits(:latn, unquote(system))

              {:ok, string}
            end
          else
            {module, function, locale_name} =
              Cldr.Config.rbnf_rule_function(definition.rules, backend)

            if locale_name in Cldr.Config.known_locale_names(config) do
              def to_system(number, unquote(system)) do
                with {:ok, _locale} <- unquote(backend).validate_locale(unquote(locale_name)) do
                  {:ok, unquote(module).unquote(function)(number, unquote(locale_name))}
                end
              end
            end
          end
        end

        def to_system(_number, system) do
          {:error, Cldr.unknown_number_system_error(system)}
        end

        @doc """
        Converts a number into the representation of
        a non-latin number system. Returns a converted
        string or raises on error.

        * `number` is a `float`, `integer` or `Decimal`

        * `system_name` is any number system name returned by
          `Cldr.known_number_systems/0` or a number system type
          returned by `Cldr.known_number_system_types/0`

        See `Cldr.Number.System.to_string/2` for further
        information.

        ## Examples

            iex> #{inspect(__MODULE__)}.to_system! 123, :hans
            "一百二十三"

            iex> #{inspect(__MODULE__)}.to_system! 123, :hant
            "一百二十三"

            iex> #{inspect(__MODULE__)}.to_system! 123, :hansfin
            "壹佰贰拾叁"

        """
        def to_system!(number, system_name) do
          case to_system(number, system_name) do
            {:ok, string} -> string
            {:error, {exception, reason}} -> raise exception, reason
          end
        end
      end
    end
  end
end
