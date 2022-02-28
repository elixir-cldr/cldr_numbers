defmodule Cldr.Number.Backend.Number do
  @moduledoc false

  def define_number_module(config) do
    backend = config.backend

    quote location: :keep, bind_quoted: [backend: backend, config: Macro.escape(config)] do
      defmodule Number do
        @moduledoc false
        if Cldr.Config.include_module_docs?(config.generate_docs) do
          @moduledoc """
          Formats numbers and currencies based upon CLDR's decimal formats specification.

          The format specification is documentated in [Unicode TR35](http://unicode.org/reports/tr35/tr35-numbers.html#Number_Formats).
          There are several classes of formatting including non-scientific, scientific,
          rules based (for spelling and ordinal formats), compact formats that display `1k`
          rather than `1,000` and so on.  See `Cldr.Number.to_string/2` for specific formatting
          options.

          ### Non-Scientific Notation Formatting

          The following description applies to formats that do not use scientific
          notation or significant digits:

          * If the number of actual integer digits exceeds the maximum integer digits,
            then only the least significant digits are shown. For example, 1997 is
            formatted as "97" if the maximum integer digits is set to 2.

          * If the number of actual integer digits is less than the minimum integer
            digits, then leading zeros are added. For example, 1997 is formatted as
            "01997" if the minimum integer digits is set to 5.

          * If the number of actual fraction digits exceeds the maximum fraction
            digits, then half-even rounding it performed to the maximum fraction
            digits. For example, 0.125 is formatted as "0.12" if the maximum fraction
            digits is 2. This behavior can be changed by specifying a rounding
            increment and a rounding mode.

          * If the number of actual fraction digits is less than the minimum fraction
            digits, then trailing zeros are added. For example, 0.125 is formatted as
            "0.1250" if the minimum fraction digits is set to 4.

          * Trailing fractional zeros are not displayed if they occur j positions after
            the decimal, where j is less than the maximum fraction digits. For example,
            0.10004 is formatted as "0.1" if the maximum fraction digits is four or
            less.

          ### Scientific Notation Formatting

          Numbers in scientific notation are expressed as the product of a mantissa and
          a power of ten, for example, 1234 can be expressed as 1.234 x 10^3. The
          mantissa is typically in the half-open interval [1.0, 10.0) or sometimes
          [0.0, 1.0), but it need not be. In a pattern, the exponent character
          immediately followed by one or more digit characters indicates scientific
          notation. Example: "0.###E0" formats the number 1234 as "1.234E3".

          * The number of digit characters after the exponent character gives the
            minimum exponent digit count. There is no maximum. Negative exponents are
            formatted using the localized minus sign, not the prefix and suffix from
            the pattern. This allows patterns such as "0.###E0 m/s". To prefix positive
            exponents with a localized plus sign, specify '+' between the exponent and
            the digits: "0.###E+0" will produce formats "1E+1", "1E+0", "1E-1", and so
            on. (In localized patterns, use the localized plus sign rather than '+'.)

          * The minimum number of integer digits is achieved by adjusting the exponent.
            Example: 0.00123 formatted with "00.###E0" yields "12.3E-4". This only
            happens if there is no maximum number of integer digits. If there is a
            maximum, then the minimum number of integer digits is fixed at one.

          * The maximum number of integer digits, if present, specifies the exponent
            grouping. The most common use of this is to generate engineering notation,
            in which the exponent is a multiple of three, for example, "##0.###E0". The
            number 12345 is formatted using "##0.####E0" as "12.345E3".

          * When using scientific notation, the formatter controls the digit counts
            using significant digits logic. The maximum number of significant digits
            limits the total number of integer and fraction digits that will be shown
            in the mantissa; it does not affect parsing. For example, 12345 formatted
            with "##0.##E0" is "12.3E3". Exponential patterns may not contain grouping
            separators.

          ### Significant Digits

          There are two ways of controlling how many digits are shows: (a)
          significant digits counts, or (b) integer and fraction digit counts. Integer
          and fraction digit counts are described above. When a formatter is using
          significant digits counts, it uses however many integer and fraction digits
          are required to display the specified number of significant digits. It may
          ignore min/max integer/fraction digits, or it may use them to the extent
          possible.
          """
        end

        alias Cldr.Number.System
        alias Cldr.Locale

        @doc """
        Return a valid number system from a provided locale and number
        system name or type.

        The number system or number system type must be valid for the
        given locale.  If a number system type is provided, the
        underlying number system is returned.

        ## Arguments

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`

        * `system_name` is any number system name returned by
          `Cldr.known_number_systems/0` or a number system type
          returned by `Cldr.known_number_system_types/0`

        ## Examples

            iex> #{inspect(__MODULE__)}.validate_number_system "en", :latn
            {:ok, :latn}

            iex> #{inspect(__MODULE__)}.validate_number_system "en", :default
            {:ok, :latn}

            iex> #{inspect(__MODULE__)}.validate_number_system "en", :unknown
            {:error,
             {Cldr.UnknownNumberSystemError, "The number system :unknown is unknown"}}

            iex> #{inspect(__MODULE__)}.validate_number_system "zz", :default
            {:error, {Cldr.InvalidLanguageError, "The language \\"zz\\" is invalid"}}

        """
        @spec validate_number_system(
                Cldr.Locale.locale_name() | Cldr.LanguageTag.t(),
                System.system_name() | System.types()
              ) ::
                {:ok, System.system_name()} | {:error, {module(), String.t()}}

        def validate_number_system(locale, number_system) do
          System.system_name_from(number_system, locale, unquote(backend))
        end

        @doc """
        Returns a number formatted into a string according to a format pattern and options.

        ## Arguments

        * `number` is an integer, float or Decimal to be formatted

        * `options` is a keyword list defining how the number is to be formatted.

        ## Options

        * `format`: the format style or a format string defining how the number is
          formatted. See `Cldr.Number.Format` for how format strings can be constructed.
          See `Cldr.Number.Format.format_styles_for/3` to return available format styles
          for a locale. The default `format` is `:standard`.

        * If `:format` is set to `:long` or `:short` then the formatting depends on
          whether `:currency` is specified. If not specified then the number is
          formatted as `:decimal_long` or `:decimal_short`. If `:currency` is
          specified the number is formatted as `:currency_long` or
          `:currency_short` and `:fractional_digits` is set to 0 as a default.

        * `:format` may also be a format defined by CLDR's Rules Based Number
          Formats (RBNF).  Further information is found in the module `Cldr.Rbnf`.
          The most commonly used formats in this category are to spell out the
          number in a the locales language.  The applicable formats are `:spellout`,
          `:spellout_year`, `:ordinal`.  A number can also be formatted as roman
          numbers by using the format `:roman` or `:roman_lower`.

        * `currency`: is the currency for which the number is formatted. For
          available currencies see `Cldr.Currency.known_currencies/0`. This option
          is required if `:format` is set to `:currency`.  If `currency` is set
          and no `:format` is set, `:format` will be set to `:currency` as well.

        * `currency_symbol`: Allows overriding a currency symbol. The alternatives
          are:
          * `:iso` the ISO currency code will be used instead of the default
            currency symbol.
          * `:narrow` uses the narrow symbol defined for the locale. The same
            narrow symbol can be defined for more than one currency and therefore this
            should be used with care. If no narrow symbol is defined, the standard
            symbol is used.
          * `:symbol` uses the standard symbol defined in CLDR. A symbol is unique
            for each currency and can be safely used.
          * "string" uses `string` as the currency symbol
          * `:standard` (the default and recommended) uses the CLDR-defined symbol
            based upon the currency format for the locale.

        * `:cash`: a boolean which indicates whether a number being formatted as a
          `:currency` is to be considered a cash value or not. Currencies can be
          rounded differently depending on whether `:cash` is `true` or `false`.
          *This option is deprecated in favour of `currency_digits: :cash`.

        * `:currency_digits` indicates which of the rounding and digits should be
          used. The options are `:accounting` which is the default, `:cash` or
          `:iso`

        * `:rounding_mode`: determines how a number is rounded to meet the precision
          of the format requested. The available rounding modes are `:down`,
          :half_up, :half_even, :ceiling, :floor, :half_down, :up. The default is
          `:half_even`.

        * `:number_system`: determines which of the number systems for a locale
          should be used to define the separators and digits for the formatted
          number. If `number_system` is an `atom` then `number_system` is
          interpreted as a number system. If the `:number_system` is
          `binary` then it is interpreted as a number system name. See
          `Cldr.Number.System.number_system_names_for/2`. The default is `:default`.

        * `:locale`: determines the locale in which the number is formatted. See
          `Cldr.known_locale_names/0`. The default is`Cldr.get_locale/0` which is the
          locale currently in affect for this `Process` and which is set by
          `Cldr.put_locale/1`.

        * If `:fractional_digits` is set to a positive integer value then the number
          will be rounded to that number of digits and displayed accordingly - overriding
          settings that would be applied by default.  For example, currencies have
          fractional digits defined reflecting each currencies minor unit.  Setting
          `:fractional_digits` will override that setting.

        * If `:maximum_integer_digits` is set to a positive integer value then the
          number is left truncated before formatting. For example if the number `1234`
          is formatted with the option `maximum_integer_digits: 2`, the number is
          truncated to `34` and formatted.

        * If `:round_nearest` is set to a positive integer value then the number
          will be rounded to nearest increment of that value - overriding
          settings that would be applied by default.

        * `:minimum_grouping_digits` overrides the CLDR definition of minimum grouping
          digits. For example in the locale `es` the number `1234` is formatted by default
          as `1345` because the locale defines the `minimium_grouping_digits` as `2`. If
          `minimum_grouping_digits: 1` is set as an option the number is formatting as
          `1.345`. The `:minimum_grouping_digits` is added to the grouping defined by
          the number format.  If the sum of these two digits is greater than the number
          of digits in the integer (or fractional) part of the number then no grouping
          is performed.

        ## Locale extensions affecting formatting

        A locale identifier can specify options that affect number formatting.
        These options are:

        * `cu`: defines what currency is implied when no curreny is specified in
          the call to `to_string/2`.

        * `cf`: defines whether to use currency or accounting format for
          formatting currencies. This overrides the `format: :currency` and `format: :accounting`
          options.

        * `nu`: defines the number system to be used if none is specified by the `:number_system`
          option to `to_string/2`

        These keys are part of the [u extension](https://unicode.org/reports/tr35/#u_Extension) and
        that document should be consulted for details on how to construct a locale identifier with these
        extensions.

        ## Returns

        * `{:ok, string}` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string 12345
            {:ok, "12,345"}

            iex> #{inspect(__MODULE__)}.to_string 12345, locale: "fr"
            {:ok, "12 345"}

            iex> #{inspect(__MODULE__)}.to_string 1345.32, currency: :EUR, locale: "es", minimum_grouping_digits: 1
            {:ok, "1.345,32 €"}

            iex> #{inspect(__MODULE__)}.to_string 1345.32, currency: :EUR, locale: "es"
            {:ok, "1345,32 €"}

            iex> #{inspect(__MODULE__)}.to_string 12345, locale: "fr", currency: "USD"
            {:ok, "12 345,00 $US"}

            iex> #{inspect(__MODULE__)}.to_string 12345, format: "#E0"
            {:ok, "1.2345E4"}

            iex> #{inspect(__MODULE__)}.to_string 12345, format: :accounting, currency: "THB"
            {:ok, "THB 12,345.00"}

            iex> #{inspect(__MODULE__)}.to_string -12345, format: :accounting, currency: "THB"
            {:ok, "(THB 12,345.00)"}

            iex> #{inspect(__MODULE__)}.to_string 12345, format: :accounting, currency: "THB",
            ...> locale: "th"
            {:ok, "฿12,345.00"}

            iex> #{inspect(__MODULE__)}.to_string 12345, format: :accounting, currency: "THB",
            ...> locale: "th", number_system: :native
            {:ok, "฿๑๒,๓๔๕.๐๐"}

            iex> #{inspect(__MODULE__)}.to_string 1244.30, format: :long
            {:ok, "1 thousand"}

            iex> #{inspect(__MODULE__)}.to_string 1244.30, format: :long, currency: "USD"
            {:ok, "1,244 US dollars"}

            iex> #{inspect(__MODULE__)}.to_string 1244.30, format: :short
            {:ok, "1K"}

            iex> #{inspect(__MODULE__)}.to_string 1244.30, format: :short, currency: "EUR"
            {:ok, "€1K"}

            iex> #{inspect(__MODULE__)}.to_string 1234, format: :spellout
            {:ok, "one thousand two hundred thirty-four"}

            iex> #{inspect(__MODULE__)}.to_string 1234, format: :spellout_verbose
            {:ok, "one thousand two hundred and thirty-four"}

            iex> #{inspect(__MODULE__)}.to_string 1989, format: :spellout_year
            {:ok, "nineteen eighty-nine"}

            iex> #{inspect(__MODULE__)}.to_string 123, format: :ordinal
            {:ok, "123rd"}

            iex> #{inspect(__MODULE__)}.to_string 123, format: :roman
            {:ok, "CXXIII"}

            iex> #{inspect(__MODULE__)}.to_string 123, locale: "th-u-nu-thai"
            {:ok, "๑๒๓"}

            iex> #{inspect(__MODULE__)}.to_string 123, format: :currency, locale: "en-u-cu-thb"
            {:ok, "THB 123.00"}

        ## Errors

        An error tuple `{:error, reason}` will be returned if an error is detected.
        The two most likely causes of an error return are:

          * A format cannot be compiled. In this case the error tuple will look like:

        ```
            iex> #{inspect(__MODULE__)}.to_string(12345, format: "0#")
            {:error, {Cldr.FormatCompileError,
              "Decimal format compiler: syntax error before: \\"#\\""}}
        ```

          * The format style requested is not defined for the `locale` and
            `number_system`. This happens typically when the number system is
            `:algorithmic` rather than the more common `:numeric`. In this case the error
            return looks like:

        ```
            iex> #{inspect(__MODULE__)}.to_string(1234, locale: "he", number_system: "hebr")
            {:error, {Cldr.UnknownFormatError,
              "The locale :he with number system :hebr does not define a format :standard"}}
        ```
        """
        @spec to_string(number | Decimal.t(), Keyword.t() | map()) ::
                {:ok, String.t()} | {:error, {atom, String.t()}}
        def to_string(number, options \\ default_options()) do
          Cldr.Number.to_string(number, unquote(backend), options)
        end

        @doc """
        Same as the execution of `to_string/2` but raises an exception if an error would be
        returned.

        ## Arguments

        * `number` is an integer, float or Decimal to be formatted

        * `options` is a keyword list defining how the number is to be formatted. See
          `#{inspect(__MODULE__)}.to_string/2`

        ## Returns

        * a formatted number as a string or

        * raises an exception

        ## Examples

            iex> #{inspect(__MODULE__)}.to_string! 12345
            "12,345"

            iex> #{inspect(__MODULE__)}.to_string! 12345, locale: "fr"
            "12 345"

        """
        @spec to_string!(number | Decimal.t(), Keyword.t() | map()) ::
                String.t() | module()
        def to_string!(number, options \\ default_options()) do
          Cldr.Number.to_string!(number, unquote(backend), options)
        end

        @doc """
        Formats a number and applies the `:at_least` format for
        a locale and number system.

        ## Arguments

        * `number` is an integer, float or Decimal to be formatted

        * `options` is a keyword list defining how the number is to be formatted.
          See `#{inspect(__MODULE__)}.to_string/2` for a description of the available
          options.

        ## Example

            iex> #{inspect(__MODULE__)}.to_at_least_string 1234
            {:ok, "1,234+"}

        """
        @spec to_at_least_string(number | Decimal.t(), Keyword.t() | Keyword.t() | map()) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}

        def to_at_least_string(number, options \\ []) do
          Cldr.Number.to_at_least_string(number, unquote(backend), options)
        end

        @doc """
        Formats a number and applies the `:at_most` format for
        a locale and number system.

        ## Arguments

        * `number` is an integer, float or Decimal to be formatted

        * `options` is a keyword list defining how the number is to be formatted.
          See `Cldr.Number.to_string/3` for a description of the available
          options.

        ## Example

            iex> #{inspect(__MODULE__)}.to_at_most_string 1234
            {:ok, "≤1,234"}

        """
        @spec to_at_most_string(number | Decimal.t(), Keyword.t() | Keyword.t() | map()) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}

        def to_at_most_string(number, options \\ []) do
          Cldr.Number.to_at_most_string(number, unquote(backend), options)
        end

        @doc """
        Formats a number and applies the `:approximately` format for
        a locale and number system.

        ## Arguments

        * `number` is an integer, float or Decimal to be formatted

        * `options` is a keyword list defining how the number is to be formatted.
          See `Cldr.Number.to_string/3` for a description of the available
          options.

        ## Example

            iex> #{inspect(__MODULE__)}.to_approx_string 1234
            {:ok, "~1,234"}

        """
        @spec to_approx_string(number | Decimal.t(), Keyword.t() | Keyword.t() | map()) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}

        def to_approx_string(number, options \\ []) do
          Cldr.Number.to_approx_string(number, unquote(backend), options)
        end

        @doc """
        Formats the first and last numbers of a range and applies
        the `:range` format for a locale and number system.

        ## Arguments

        * `number` is an integer, float or Decimal to be formatted

        * `options` is a keyword list defining how the number is to be formatted.
          See `Cldr.Number.to_string/3` for a description of the available
          options.

        ## Example

            iex> #{inspect(__MODULE__)}.to_range_string 1234..5678
            {:ok, "1,234–5,678"}

        """
        @spec to_range_string(Range.t(), Keyword.t() | Keyword.t() | map()) ::
                {:ok, String.t()} | {:error, {module(), String.t()}}

        def to_range_string(range, options \\ []) do
          Cldr.Number.to_range_string(range, unquote(backend), options)
        end

        @doc """
        Scans a string locale-aware manner and returns
        a list of strings and numbers.

        ## Arguments

        * `string` is any `String.t`

        * `options` is a keyword list of options

        ## Options

        * `:number` is one of `:integer`, `:float`,
          `:decimal` or `nil`. The default is `nil`
          meaning that the type auto-detected as either
          an `integer` or a `float`.

        * `:locale` is any locale returned by `Cldr.known_locale_names/1`
          or a `Cldr.LanguageTag.t`. The default is `#{inspect backend}.get_locale/0`.

        ## Returns

        * A list of strings and numbers

        ## Notes

        Number parsing is performed by `Cldr.Number.Parser.parse/2`
        and any options provided are passed to that function.

        ## Examples

            iex> #{inspect(__MODULE__)}.scan("£1_000_000.34")
            ["£", 1000000.34]

            iex> #{inspect(__MODULE__)}.scan("I want £1_000_000 dollars")
            ["I want £", 1000000, " dollars"]

            iex> #{inspect(__MODULE__)}.scan("The prize is 23")
            ["The prize is ", 23]

            iex> #{inspect(__MODULE__)}.scan("The lottery number is 23 for the next draw")
            ["The lottery number is ", 23, " for the next draw"]

            iex> #{inspect(__MODULE__)}.scan("The loss is -1.000 euros", locale: "de", number: :integer)
            ["The loss is ", -1000, " euros"]

        """
        def scan(string, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Number.Parser.scan(string, options)
        end

        @doc """
        Parse a string locale-aware manner and return
        a number.

        ## Arguments

        * `string` is any `String.t`

        * `options` is a keyword list of options

        ## Options

        * `:number` is one of `:integer`, `:float`,
          `:decimal` or `nil`. The default is `nil`
          meaning that the type auto-detected as either
          an `integer` or a `float`.

        * `:locale` is any locale returned by
          `#{inspect backend}.known_locale_names/0`
          or a `Cldr.LanguageTag.t`. The default is
          `#{inspect backend}.get_locale/0`.

        ## Returns

        * A number of the requested or default type or

        * `{:error, {exception, error}}` if no number could be determined

        ## Notes

        This function parses a string to return a number but
        in a locale-aware manner. It will normalise grouping
        characters and decimal separators, different forms of
        the `+` and `-` symbols that appear in Unicode and
        strips any `_` characters that might be used for
        formatting in a string. It then parses the number
        using the Elixir standard library functions.

        ## Examples

            iex> #{inspect(__MODULE__)}.parse("＋1.000,34", locale: "de")
            {:ok, 1000.34}

            iex> #{inspect(__MODULE__)}.parse("-1_000_000.34")
            {:ok, -1000000.34}

            iex> #{inspect(__MODULE__)}.parse("1.000", locale: "de", number: :integer)
            {:ok, 1000}

            iex> #{inspect(__MODULE__)}.parse("＋1.000,34", locale: "de", number: :integer)
            {:error,
              {Cldr.Number.ParseError,
               "The string \\"＋1.000,34\\" could not be parsed as a number"}}

        """
        def parse(string, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Number.Parser.parse(string, options)
        end

        @doc """
        Resolve curencies from strings within
        a list.

        ## Arguments

        * `list` is any list in which currency
          names and symbols are expected

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale returned by `Cldr.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`
          The default is `#{inspect backend}.get_locale()`

        * `:only` is an `atom` or list of `atoms` representing the
          currencies or currency types to be considered for a match.
          The equates to a list of acceptable currencies for parsing.
          See the notes below for currency types.

        * `:except` is an `atom` or list of `atoms` representing the
          currencies or currency types to be not considered for a match.
          This equates to a list of unacceptable currencies for parsing.
          See the notes below for currency types.

        * `:fuzzy` is a float greater than `0.0` and less than or
          equal to `1.0` which is used as input to
          `String.jaro_distance/2` to determine is the provided
          currency string is *close enough* to a known currency
          string for it to identify definitively a currency code.
          It is recommended to use numbers greater than `0.8` in
          order to reduce false positives.

        ## Notes

        The `:only` and `:except` options accept a list of
        currency codes and/or currency types.  The following
        types are recognised.

        If both `:only` and `:except` are specified,
        the `:except` entries take priority - that means
        any entries in `:except` are removed from the `:only`
        entries.

          * `:all`, the default, considers all currencies

          * `:current` considers those currencies that have a `:to`
            date of nil and which also is a known ISO4217 currency

          * `:historic` is the opposite of `:current`

          * `:tender` considers currencies that are legal tender

          * `:unannotated` considers currencies that don't have
            "(some string)" in their names.  These are usually
            financial instruments.

        ## Examples

            iex> #{inspect(__MODULE__)}.scan("100 US dollars")
            ...> |> #{inspect(__MODULE__)}.resolve_currencies
            [100, :USD]

            iex> #{inspect(__MODULE__)}.scan("100 eurosports")
            ...> |> #{inspect(__MODULE__)}.resolve_currencies(fuzzy: 0.75)
            [100, :EUR]

            iex> #{inspect(__MODULE__)}.scan("100 dollars des États-Unis")
            ...> |> #{inspect(__MODULE__)}.resolve_currencies(locale: "fr")
            [100, :USD]

        """
        def resolve_currencies(list, options \\ []) when is_list(list) and is_list(options) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Number.Parser.resolve_currencies(list, options)
        end

        @doc """
        Resolve a currency from a string

        ## Arguments

        * `list` is any list in which currency
          names and symbols are expected

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale returned by `Cldr.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`
          The default is `#{inspect backend}.get_locale()`

        * `:only` is an `atom` or list of `atoms` representing the
          currencies or currency types to be considered for a match.
          The equates to a list of acceptable currencies for parsing.
          See the notes below for currency types.

        * `:except` is an `atom` or list of `atoms` representing the
          currencies or currency types to be not considered for a match.
          This equates to a list of unacceptable currencies for parsing.
          See the notes below for currency types.

        * `:fuzzy` is a float greater than `0.0` and less than or
          equal to `1.0` which is used as input to
          `String.jaro_distance/2` to determine is the provided
          currency string is *close enough* to a known currency
          string for it to identify definitively a currency code.
          It is recommended to use numbers greater than `0.8` in
          order to reduce false positives.

        ## Returns

        * An ISO4217 currency code as an atom or

        * `{:error, {exception, message}}`

        ## Notes

        The `:only` and `:except` options accept a list of
        currency codes and/or currency types.  The following
        types are recognised.

        If both `:only` and `:except` are specified,
        the `:except` entries take priority - that means
        any entries in `:except` are removed from the `:only`
        entries.

          * `:all`, the default, considers all currencies

          * `:current` considers those currencies that have a `:to`
            date of nil and which also is a known ISO4217 currency

          * `:historic` is the opposite of `:current`

          * `:tender` considers currencies that are legal tender

          * `:unannotated` considers currencies that don't have
            "(some string)" in their names.  These are usually
            financial instruments.

        ## Examples

            iex> #{inspect(__MODULE__)}.resolve_currency("US dollars")
            [:USD]

            iex> #{inspect(__MODULE__)}.resolve_currency("100 eurosports", fuzzy: 0.75)
            [:EUR]

            iex> #{inspect(__MODULE__)}.resolve_currency("dollars des États-Unis", locale: "fr")
            [:USD]

            iex> #{inspect(__MODULE__)}.resolve_currency("not a known currency", locale: "fr")
            {:error,
             {Cldr.UnknownCurrencyError,
              "The currency \\"not a known currency\\" is unknown or not supported"}}

        """
        def resolve_currency(string, options \\ []) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Number.Parser.resolve_currency(string, options)
        end

        @doc """
        Resolve and tokenize percent and permille
        sybols from strings within a list.

        Percent and permille symbols can be identified
        at the beginning and/or the end of a string.

        ## Arguments

        * `list` is any list in which percent and
          permille symbols are expected

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale returned by `Cldr.known_locale_names/1`
          or a `t:Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`
          The default is `options[:backend].get_locale()`

        ## Examples

            iex> #{inspect(__MODULE__)}.scan("100%")
            ...> |> #{inspect(__MODULE__)}.resolve_pers()
            [100, :percent]

        """

        @doc since: "2.22.0"

        @spec resolve_pers([String.t(), ...], Keyword.t()) ::
          list(Cldr.Number.Parser.per() | String.t())

        def resolve_pers(list, options \\ []) when is_list(list) and is_list(options) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Number.Parser.resolve_pers(list, options)
        end

        @doc """
        Resolve and tokenize percent or permille
        from the beginning and/or the end of a string

        ## Arguments

        * `list` is any list in which percent
          and permille symbols are expected

        * `options` is a keyword list of options

        ## Options

        * `:locale` is any valid locale returned by `Cldr.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`
          The default is `options[:backend].get_locale()`

        ## Returns

        * An `:percent` or `permille` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> #{inspect(__MODULE__)}.resolve_per "11%"
            ["11", :percent]

            iex> #{inspect(__MODULE__)}.resolve_per "% of linguists"
            [:percent, " of linguists"]

            iex> #{inspect(__MODULE__)}.resolve_per "% of linguists %"
            [:percent, " of linguists ", :percent]

        """

        @doc since: "2.22.0"

        @spec resolve_per(String.t(), Keyword.t()) ::
          Cldr.Number.Parser.per() | list(Cldr.Number.Parser.per() | String.t()) |
          {:error, {module(), String.t()}}

        def resolve_per(string, options \\ []) when is_binary(string) do
          options = Keyword.put(options, :backend, unquote(backend))
          Cldr.Number.Parser.resolve_per(string, options)
        end

        @doc false
        def default_options do
          [
            format: :standard,
            currency: nil,
            currency_digits: :accounting,
            minimum_grouping_digits: 0,
            rounding_mode: :half_even,
            number_system: :default,
            locale: unquote(backend).get_locale()
          ]
        end
      end
    end
  end
end
