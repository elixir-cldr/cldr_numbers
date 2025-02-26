defmodule Cldr.Number.Backend.Transliterate do
  @moduledoc false

  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Number.Transliterate do
        @moduledoc false
        if Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc """
          Transliteration for digits and separators.

          Transliterating a string is an expensive business.  First the string has to
          be exploded into its component graphemes.  Then for each grapheme we have
          to map to the equivalent in the other `{locale, number_system}`.  Then we
          have to reassemble the string.

          Effort is made to short circuit where possible. Transliteration is not
          required for any `{locale, number_system}` that is the same as `{"en",
          "latn"}` since the implementation uses this combination for the placeholders during
          formatting already. When short circuiting is possible (typically the en-*
          locales with "latn" number_system - the total number of short circuited
          locales is 211 of the 537 in CLDR) the overall number formatting is twice as
          fast than when formal transliteration is required.

          ### Configuring precompilation of digit transliterations

          This module includes `Cldr.Number.Transliterate.transliterate_digits/3` which transliterates
          digits between number systems.  For example from :arabic to :latn.  Since generating a
          transliteration map is slow, pairs of transliterations can be configured so that the
          transliteration map is created at compile time and therefore speeding up transliteration at
          run time.

          To configure these transliteration pairs, add the to the `use Cldr` configuration
          in a backend module:

              defmodule MyApp.Cldr do
                use Cldr,
                locale: ["en", "fr", "th"],
                default_locale: "en",
                precompile_transliterations: [{:latn, :thai}, {:arab, :thai}]
              end

          Where each tuple in the list configures one transliteration map.  In this example, two maps are
          configured: from `:latn` to `:thai` and from `:arab` to `:thai`.

          A list of configurable number systems is returned by `Cldr.Number.System.numeric_systems/0`.

          If a transliteration is requested between two number pairs that have not been configured for
          precompilation, a warning is logged.

          """
        end

        alias Cldr.Number.System
        alias Cldr.Number.Symbol
        alias Cldr.Number.Format.Compiler
        alias Cldr.LanguageTag
        alias Cldr.Config

        @doc """
        Transliterates from latin digits to another number system's digits.

        Transliterates the latin digits 0..9 to their equivalents in
        another number system. Also transliterates the decimal and grouping
        separators as well as the plus, minus and exponent symbols. Any other character
        in the string will be returned "as is".

        ## Arguments

        * `sequence` is the string to be transliterated.

        * `locale` is any known locale, defaulting to `#{inspect(backend)}.get_locale/0`.

        * `number_system` is any known number system. If expressed as a `string` it
          is the actual name of a known number system. If epressed as an `atom` it is
          used as a key to look up a number system for the locale (the usual keys are
          `:default` and `:native` but :traditional and :finance are also part of the
          standard). See `#{inspect(backend)}.Number.System.number_systems_for/1` for a locale to
          see what number system types are defined. The default is `:default`.

        For available number systems see `Cldr.Number.System.number_systems/0`
        and `#{inspect(backend)}.Number.System.number_systems_for/1`.  Also see
        `#{inspect(backend)}.Number.Symbol.number_symbols_for/1`.


        ## Examples

            iex> #{inspect(__MODULE__)}.transliterate("123556")
            "123556"

            iex> #{inspect(__MODULE__)}.transliterate("123,556.000", "fr", :default)
            "123 556,000"

            iex> #{inspect(__MODULE__)}.transliterate("123556", "th", :default)
            "123556"

            iex> #{inspect(__MODULE__)}.transliterate("123556", "th", "thai")
            "๑๒๓๕๕๖"

            iex> #{inspect(__MODULE__)}.transliterate("123556", "th", :native)
            "๑๒๓๕๕๖"

            iex> #{inspect(__MODULE__)}.transliterate("Some number is: 123556", "th", "thai")
            "Some number is: ๑๒๓๕๕๖"

        """

        @spec transliterate(
                String.t(),
                LanguageTag.t() | Cldr.Locale.locale_name(),
                Cldr.Number.System.system_name() | Cldr.Number.System.types(),
                map() | Keyword.t()
              ) ::
                String.t() | {:error, {module(), String.t()}}

        def transliterate(
              sequence,
              locale \\ unquote(backend).get_locale(),
              number_system \\ System.default_number_system_type(),
              options \\ %{}
            )

        def transliterate(sequence, locale, number_system, options) when is_list(options) do
          transliterate(sequence, locale, number_system, Map.new(options))
        end

        # No transliteration required when the digits and separators as the same
        # as the ones we use in formatting.
        with {:ok, systems} <- Config.known_number_systems_like(:en, :latn, config) do
          for {locale, system} <- systems do
            def transliterate(
                  sequence,
                  %LanguageTag{cldr_locale_name: unquote(locale)},
                  unquote(system),
                  options
                ) do
              sequence
            end
          end
        end

        # We can only transliterate if the target {locale, number_system} has defined
        # digits.  Some systems don't have digits, just rules.
        for {number_system, %{digits: _digits}} <- System.numeric_systems() do
          def transliterate(sequence, locale, unquote(number_system), options) do
            sequence
            |> String.graphemes()
            |> Enum.map(&transliterate_char(&1, locale, unquote(number_system), options))
            |> Elixir.List.to_string()
          end
        end

        # String locale name needs validation
        def transliterate(sequence, locale_name, number_system, options) when is_binary(locale_name) do
          with {:ok, locale} <- Module.concat(unquote(backend), :Locale).new(locale_name) do
            transliterate(sequence, locale, number_system, options)
          end
        end

        # For when the system name is not known (because its probably a system type
        # like :default, or :native)
        def transliterate(sequence, locale_name, number_system, options) do
          with {:ok, system_name} <-
                 System.system_name_from(number_system, locale_name, unquote(backend)) do
            transliterate(sequence, locale_name, system_name, options)
          end
        end

        def transliterate!(sequence, locale, number_system, options) do
          case transliterate(sequence, locale, number_system, options) do
            {:error, {exception, reason}} -> raise exception, reason
            string -> string
          end
        end

        # Functions to transliterate the symbols
        for locale_name <- Cldr.Locale.Loader.known_locale_names(config),
            {name, symbols} <- Config.number_symbols_for!(locale_name, config),
            !is_nil(symbols) do
          # Mapping for the grouping separator
          defp transliterate_char(
                 unquote(Compiler.placeholder(:group)),
                 %LanguageTag{cldr_locale_name: unquote(locale_name)},
                 unquote(name),
                 options
               ) do
            group_symbols = unquote(Macro.escape(symbols.group))
            group_option = Map.get(options, :separators, :standard)
            Map.get(group_symbols, group_option)
          end

          # Mapping for the decimal separator
          defp transliterate_char(
                 unquote(Compiler.placeholder(:decimal)),
                 %LanguageTag{cldr_locale_name: unquote(locale_name)},
                 unquote(name),
                 options
               ) do
            decimal_symbols = unquote(Macro.escape(symbols.decimal))
            decimal_option = Map.get(options, :separators, :standard)
            Map.get(decimal_symbols, decimal_option)
          end

          # Mapping for the exponent
          defp transliterate_char(
                 unquote(Compiler.placeholder(:exponent)),
                 %LanguageTag{cldr_locale_name: unquote(locale_name)},
                 unquote(name),
                 _options
               ) do
            unquote(symbols.exponential)
          end

          # Mapping for the plus sign
          defp transliterate_char(
                 unquote(Compiler.placeholder(:plus)),
                 %LanguageTag{cldr_locale_name: unquote(locale_name)},
                 unquote(name),
                 _options
               ) do
            unquote(symbols.plus_sign)
          end

          # Mapping for the minus sign
          defp transliterate_char(
                 unquote(Compiler.placeholder(:minus)),
                 %LanguageTag{cldr_locale_name: unquote(locale_name)},
                 unquote(name),
                 _options
               ) do
            unquote(symbols.minus_sign)
          end
        end

        # Functions to transliterate the digits
        for {name, %{digits: digits}} <- System.numeric_systems() do
          graphemes = String.graphemes(digits)

          for latin_digit <- 0..9 do
            grapheme = :lists.nth(latin_digit + 1, graphemes)
            latin_char = Integer.to_string(latin_digit)

            defp transliterate_char(unquote(latin_char), _locale, unquote(name), _options) do
              unquote(grapheme)
            end
          end
        end

        # Any unknown mapping gets returned as is
        defp transliterate_char(digit, _locale, _name, _options) do
          digit
        end

        @doc """
        Transliterates digits from one number system to another number system

        * `digits` is binary representation of a number

        * `from_system` and `to_system` are number system names in atom form.  See
        `Cldr.Number.System.numeric_systems/0` for available number systems.

        ## Example

            iex> #{inspect(__MODULE__)}.transliterate_digits "٠١٢٣٤٥٦٧٨٩", :arab, :latn
            "0123456789"

        """
        @spec transliterate_digits(String.t(), System.system_name(), System.system_name()) ::
                String.t()

        for {from_system, to_system} <- Map.get(config, :precompile_transliterations, []) do
          with {:ok, from} = System.number_system_digits(from_system),
               {:ok, to} = System.number_system_digits(to_system),
               map = System.generate_transliteration_map(from, to) do
            def transliterate_digits(digits, unquote(from_system), unquote(to_system)) do
              do_transliterate_digits(digits, unquote(Macro.escape(map)))
            end
          end
        end

        def transliterate_digits(digits, from_system, to_system) when is_binary(digits) do
          Cldr.Number.Transliterate.transliterate_digits(digits, from_system, to_system)
        end

        defp do_transliterate_digits(digits, map) do
          digits
          |> String.graphemes()
          |> Enum.map(&Map.get(map, &1, &1))
          |> Enum.join()
        end
      end
    end
  end
end
