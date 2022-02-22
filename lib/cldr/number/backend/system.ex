defmodule Cldr.Number.Backend.System do
  @moduledoc false

  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Number.System do
        unless Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc false
        end

        @doc """
        Returns the number system from a language tag or
        locale name.

        ## Arguments

        * `locale` is any language tag returned be `Cldr.Locale.new/2`
          or a locale name in the list returned by `Cldr.known_locale_names/1`

        ## Returns

        * A number system name as an atom

        ## Examples

            iex> #{inspect __MODULE__}.number_system_from_locale "en-US-u-nu-thai"
            :thai

            iex> #{inspect __MODULE__}.number_system_from_locale "en-US"
            :latn

        """
        @spec number_system_from_locale(Cldr.Locale.locale_reference()) ::
          Cldr.Number.System.system_name

        def number_system_from_locale(locale) do
          Cldr.Number.System.number_system_from_locale(locale, unquote(backend))
        end

        @doc """
        Returns the number systems available for a locale
        or `{:error, message}` if the locale is not known.

        * `locale` is any valid locale name returned by `#{inspect(backend)}.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `#{inspect(backend)}.Locale.new!/1`

        ## Examples

            iex> #{inspect(__MODULE__)}.number_systems_for "en"
            {:ok, %{default: :latn, native: :latn}}

            iex> #{inspect(__MODULE__)}.number_systems_for "th"
            {:ok, %{default: :latn, native: :thai}}

            iex> #{inspect(__MODULE__)}.number_systems_for "zz"
            {:error, {Cldr.InvalidLanguageError, "The language \\"zz\\" is invalid"}}

        """
        @spec number_systems_for(Cldr.Locale.locale_reference()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

        def number_systems_for(locale)

        @doc """
        Returns the number systems available for a locale
        or `{:error, message}` if the locale is not known.

        * `locale` is any valid locale name returned by `#{inspect(backend)}.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `#{inspect(backend)}.Locale.new!/1`

        ## Examples

            iex> #{inspect(__MODULE__)}.number_system_names_for "en"
            {:ok, [:latn]}

            iex> #{inspect(__MODULE__)}.number_system_names_for "zz"
            {:error, {Cldr.InvalidLanguageError, "The language \\"zz\\" is invalid"}}

        """
        @spec number_system_names_for(Cldr.Locale.locale_reference()) ::
                {:ok, list(atom())} | {:error, {module(), String.t()}}

        def number_system_names_for(locale)

        for locale_name <- Cldr.Locale.Loader.known_locale_names(config) do
          systems =
            locale_name
            |> Cldr.Locale.Loader.get_locale(config)
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

        def number_systems_for(locale_name) when Cldr.is_locale_name(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            number_systems_for(locale)
          end
        end

        def number_systems_for!(locale) do
          case number_systems_for(locale) do
            {:ok, systems} -> systems
            {:error, {exception, reason}} -> raise exception, reason
          end
        end

        def number_system_names_for!(locale) do
          case number_system_names_for(locale) do
            {:ok, names} -> names
            {:error, {exception, reason}} -> raise exception, reason
          end
        end

        @doc """
        Returns the actual number system from a number system type.

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

        * `system_name` is any number system name returned by
          `Cldr.known_number_systems/0` or a number system type
          returned by `Cldr.known_number_system_types/0`

        This function will decode a number system type into the actual
        number system.  If the number system provided can't be decoded
        it is returned as is.

        ## Examples

            iex> #{inspect __MODULE__}.number_system_for "th", :latn
            {:ok, %{digits: "0123456789", type: :numeric}}

            iex> #{inspect __MODULE__}.number_system_for "en", :default
            {:ok, %{digits: "0123456789", type: :numeric}}

            iex> #{inspect __MODULE__}.number_system_for "he", :traditional
            {:ok, %{rules: "hebrew", type: :algorithmic}}

            iex> #{inspect __MODULE__}.number_system_for "en", :native
            {:ok, %{digits: "0123456789", type: :numeric}}

            iex> #{inspect __MODULE__}.number_system_for "en", :finance
            {
              :error,
              {Cldr.UnknownNumberSystemError,
                "The number system :finance is unknown for the locale named :en. Valid number systems are %{default: :latn, native: :latn}"}
            }

        """
        @spec number_system_for(Cldr.Locale.locale_reference(), Cldr.Number.System.system_name()) ::
          {:ok, list(atom())} | {:error, {module(), String.t()}}

        def number_system_for(locale, system_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale),
               {:ok, system_name} <- system_name_from(system_name, locale) do
            {:ok, Map.get(Cldr.Number.System.number_systems(), system_name)}
          end
        end

        def number_system_names_for(locale) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale) do
            number_system_names_for(locale)
          end
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
            {:ok, "קכ״ג׳תנ״ו"}

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

            if locale_name in Cldr.Locale.Loader.known_locale_names(config) do
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
          `#{inspect(backend)}.known_number_systems/0` or a number system type
          returned by `#{inspect(backend)}.known_number_system_types/0`

        See `#{inspect(__MODULE__)}.to_system/2` for further
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

        @doc """
        Returns a number system name for a given locale and number system reference.

        * `system_name` is any number system name returned by
          `#{inspect(backend)}.known_number_systems/0` or a number system type
          returned by `#{inspect(backend)}.known_number_system_types/0`

        * `locale` is any valid locale name returned by `#{inspect(backend)}.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `#{inspect(backend)}.Locale.new!/1`

        Number systems can be references in one of two ways:

        * As a number system type such as :default, :native, :traditional and
          :finance. This allows references to a number system for a locale in a
          consistent fashion for a given use

        * WIth the number system name directly, such as :latn, :arab or any of the
          other 70 or so

        This function dereferences the supplied `system_name` and returns the
        actual system name.

        ## Examples

            ex> #{inspect(__MODULE__)}.system_name_from(:default, "en")
            {:ok, :latn}

            iex> #{inspect(__MODULE__)}.system_name_from("latn", "en")
            {:ok, :latn}

            iex> #{inspect(__MODULE__)}.system_name_from(:native, "en")
            {:ok, :latn}

            iex> #{inspect(__MODULE__)}.system_name_from(:nope, "en")
            {
              :error,
              {Cldr.UnknownNumberSystemError, "The number system :nope is unknown"}
            }

        Note that return value is not guaranteed to be a valid
        number system for the given locale as demonstrated in the third example.

        """
        @spec system_name_from(
                Cldr.Number.System.system_name(),
                Cldr.Locale.locale_name() | LanguageTag.t()
              ) :: {:ok, atom} | {:error, {module(), String.t()}}

        def system_name_from(system_name, locale) do
          Cldr.Number.System.system_name_from(system_name, locale, unquote(backend))
        end

        @spec number_systems_like(Cldr.Locale.locale_reference(), Cldr.Number.System.system_name()) ::
          {:ok, list()} | {:error, tuple}

        def number_systems_like(locale, number_system) do
          Cldr.Number.System.number_systems_like(locale, number_system, unquote(backend))
        end
      end
    end
  end
end
