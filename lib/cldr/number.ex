defmodule Cldr.Number do
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

  alias Cldr.Config
  alias Cldr.Number.Formatter
  alias Cldr.Number.Format.Options

  @type format_type ::
          :standard
          | :decimal_short
          | :decimal_long
          | :currency_short
          | :currency_long
          | :percent
          | :accounting
          | :scientific
          | :currency

  @short_format_styles Options.short_format_styles()
  @root_locale_name Config.root_locale_name()
  @root_locale Map.fetch!(Config.all_language_tags(), @root_locale_name)

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

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  ## Examples

      iex> Cldr.Number.validate_number_system :en, :latn, TestBackend.Cldr
      {:ok, :latn}

      iex> Cldr.Number.validate_number_system :en, :default, TestBackend.Cldr
      {:ok, :latn}

      iex> Cldr.Number.validate_number_system :en, :unknown, TestBackend.Cldr
      {:error,
       {Cldr.UnknownNumberSystemError, "The number system :unknown is unknown"}}

      iex> Cldr.Number.validate_number_system "zz", :default, TestBackend.Cldr
      {:error, {Cldr.InvalidLanguageError, "The language \\"zz\\" is invalid"}}

  """
  @spec validate_number_system(
          Cldr.Locale.locale_name() | Cldr.LanguageTag.t(),
          Cldr.Number.System.system_name() | Cldr.Number.System.types(),
          Cldr.backend()
        ) ::
          {:ok, Cldr.Number.System.system_name()} | {:error, {module(), String.t()}}

  def validate_number_system(locale, number_system, backend \\ default_backend()) do
    Cldr.Number.System.system_name_from(number_system, locale, backend)
  end

  @doc """
  Returns a number formatted into a string according to a format pattern and options.

  ## Arguments

  * `number` is an integer, float or Decimal to be formatted

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  * `options` is a keyword list defining how the number is to be formatted. The
    valid options are:

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

  * If `:format` is set to `:currency_long_with_symbol` then a format composed
    of `:currency_long` with the locale's currency format is used.

  * `:format` may also be a format defined by CLDR's Rules Based Number
    Formats (RBNF).  Further information is found in the module `Cldr.Rbnf`.
    The most commonly used formats in this category are to spell out the
    number in a the locales language.  The applicable formats are `:spellout`,
    `:spellout_year`, `:ordinal`.  A number can also be formatted as roman
    numbers by using the format `:roman` or `:roman_lower`.

  * `currency`: is the currency for which the number is formatted. This option
    is required if `:format` is set to `:currency`.  If `currency` is set
    and no `:format` is set, `:format` will be set to `:currency` as well.
    Currency may be any [ISO 4217 currency code](https://en.wikipedia.org/wiki/ISO_4217)
    returned by `Cldr.Currency.known_currencies/0` or a
    [ISO 24165](https://www.iso.org/standard/80601.html) digital token
    identifier (crypto currency).

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
    *This option is deprecated in favour of `currency_digits: :cash`. Ignored
    if the currency is a digital token.

  * `:currency_digits` indicates which of the rounding and digits should be
    used. The options are `:accounting` which is the default, `:cash` or
    `:iso`. Ignored if the currency is a digital token.

  * `:rounding_mode`: determines how a number is rounded to meet the precision
    of the format requested. The available rounding modes are `:down`,
    :half_up, :half_even, :ceiling, :floor, :half_down, :up. The default is
    `:half_even`.

  * `:number_system`: determines which of the number systems for a locale
    should be used to define the separators and digits for the formatted
    number. If `number_system` is an `atom` then `number_system` is
    interpreted as a number system. See
    `Cldr.Number.System.number_systems_for/2`. If the `:number_system` is
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
    digits. For example in the locale `es` the number `1345` is formatted by default
    as `1345` because the locale defines the `minimium_grouping_digits` as `2`. If
    `minimum_grouping_digits: 1` is set as an option the number is formatted as
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

      iex> Cldr.Number.to_string 12345, TestBackend.Cldr
      {:ok, "12,345"}

      iex> Cldr.Number.to_string 12345, TestBackend.Cldr, locale: "fr"
      {:ok, "12 345"}

      iex> Cldr.Number.to_string 1345.32, TestBackend.Cldr, currency: :EUR, locale: "es", minimum_grouping_digits: 1
      {:ok, "1.345,32 €"}

      iex> Cldr.Number.to_string 1345.32, TestBackend.Cldr, currency: :EUR, locale: "es"
      {:ok, "1345,32 €"}

      iex> Cldr.Number.to_string 12345, TestBackend.Cldr, locale: "fr", currency: "USD"
      {:ok, "12 345,00 $US"}

      iex> Cldr.Number.to_string 12345, TestBackend.Cldr, format: "#E0"
      {:ok, "1.2345E4"}

      iex> Cldr.Number.to_string 12345, TestBackend.Cldr, format: :accounting, currency: "THB"
      {:ok, "THB 12,345.00"}

      iex> Cldr.Number.to_string -12345, TestBackend.Cldr, format: :accounting, currency: "THB"
      {:ok, "(THB 12,345.00)"}

      iex> Cldr.Number.to_string 12345, TestBackend.Cldr, format: :accounting, currency: "THB",
      ...> locale: "th"
      {:ok, "฿12,345.00"}

      iex> Cldr.Number.to_string 12345, TestBackend.Cldr, format: :accounting, currency: "THB",
      ...> locale: "th", number_system: :native
      {:ok, "฿๑๒,๓๔๕.๐๐"}

      iex> Cldr.Number.to_string 1244.30, TestBackend.Cldr, format: :long
      {:ok, "1 thousand"}

      iex> Cldr.Number.to_string 1244.30, TestBackend.Cldr, format: :long, currency: "USD"
      {:ok, "1,244 US dollars"}

      iex> Cldr.Number.to_string 1244.30, TestBackend.Cldr, format: :short
      {:ok, "1K"}

      iex> Cldr.Number.to_string 1244.30, TestBackend.Cldr, format: :short, currency: "EUR"
      {:ok, "€1K"}

      iex> Cldr.Number.to_string 1234, TestBackend.Cldr, format: :spellout
      {:ok, "one thousand two hundred thirty-four"}

      iex> Cldr.Number.to_string 1234, TestBackend.Cldr, format: :spellout_verbose
      {:ok, "one thousand two hundred and thirty-four"}

      iex> Cldr.Number.to_string 1989, TestBackend.Cldr, format: :spellout_year
      {:ok, "nineteen eighty-nine"}

      iex> Cldr.Number.to_string 123, TestBackend.Cldr, format: :ordinal
      {:ok, "123rd"}

      iex> Cldr.Number.to_string 123, TestBackend.Cldr, format: :roman
      {:ok, "CXXIII"}

      iex> Cldr.Number.to_string 123, TestBackend.Cldr, locale: "th-u-nu-thai"
      {:ok, "๑๒๓"}

      iex> Cldr.Number.to_string 123, TestBackend.Cldr, format: :currency, locale: "en-u-cu-thb"
      {:ok, "THB 123.00"}

  ## Errors

  An error tuple `{:error, reason}` will be returned if an error is detected.
  The two most likely causes of an error return are:

    * A format cannot be compiled. In this case the error tuple will look like:

  ```
      iex> Cldr.Number.to_string(12345, TestBackend.Cldr, format: "0#")
      {:error, {Cldr.FormatCompileError,
        "Decimal format compiler: syntax error before: \\"#\\""}}
  ```

    * The format style requested is not defined for the `locale` and
      `number_system`. This happens typically when the number system is
      `:algorithmic` rather than the more common `:numeric`. In this case the error
      return looks like:

  ```
      iex> Cldr.Number.to_string(1234, TestBackend.Cldr, locale: "he", number_system: "hebr")
      {:error, {Cldr.UnknownFormatError,
      "The locale :he with number system :hebr does not define a format :standard"}}
  ```
  """
  @spec to_string(number | Decimal.t() | String.t(), Cldr.backend() | Keyword.t() | map(), Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {atom, String.t()}}

  def to_string(number, backend \\ default_backend(), options \\ [])

  # No backend supplied, just options
  def to_string(number, options, []) when is_list(options) do
    {backend, options} = Keyword.pop_lazy(options, :backend, &default_backend/0)
    to_string(number, backend, options)
  end

  # Decimal -0 is formatted like 0, without the sign
  def to_string(%Decimal{coef: 0, sign: -1} = number, backend, options) do
    %Decimal{number | sign: 1}
    |> to_string(backend, options)
  end

  # Pre-processed options which is nearly twice as
  # fast as non-preprocessed.  See
  # Cldr.Number.Options.validate_options/3
  def to_string(number, backend, %Options{} = options) do
    case to_string(number, options.format, backend, options) do
      {:error, reason} -> {:error, reason}
      string -> {:ok, string}
    end
  end

  def to_string(number, backend, options) when is_list(options) do
    with {:ok, options} <- Options.validate_options(number, backend, options) do
      to_string(number, backend, options)
    end
  end

  @doc """
  Same as the execution of `to_string/2` but raises an exception if an error would be
  returned.

  ## Options

  * `number` is an integer, float or Decimal to be formatted

  * `options` is a keyword list defining how the number is to be formatted. See
    `Cldr.Number.to_string/2`

  ## Returns

  * a formatted number as a string or

  * raises an exception

  ## Examples

      iex> Cldr.Number.to_string! 12345, TestBackend.Cldr
      "12,345"

      iex> Cldr.Number.to_string! 12345, TestBackend.Cldr, locale: "fr"
      "12 345"

  """
  @spec to_string!(
          number | Decimal.t() | String.t(),
          Cldr.backend() | Keyword.t() | map(),
          Keyword.t() | map()
        ) ::
          String.t() | no_return()

  def to_string!(number, backend \\ default_backend(), options \\ [])

  def to_string!(number, backend, options) do
    case to_string(number, backend, options) do
      {:error, {exception, message}} ->
        raise exception, message

      {:ok, string} ->
        string
    end
  end

  @format_mapping [
    {:ordinal, :digits_ordinal, Ordinal},
    {:spellout, :spellout_numbering, Spellout},
    {:spellout_verbose, :spellout_numbering_verbose, Spellout},
    {:spellout_year, :spellout_numbering_year, Spellout},
  ]

  for {format, function, module} <- @format_mapping do
    defp to_string(number, unquote(format), backend, options) do
      evaluate_rule(number, unquote(module), unquote(function), options.locale, backend)
    end
  end

  # For Roman numerals
  defp to_string(number, :roman, backend, _options) do
    Module.concat(backend, Rbnf.NumberSystem).roman_upper(number, @root_locale)
  end

  defp to_string(number, :roman_lower, backend, _options) do
    Module.concat(backend, Rbnf.NumberSystem).roman_lower(number, @root_locale)
  end

  # For the :currency_long format only
  defp to_string(number, :currency_long = format, backend, options) do
    Formatter.Currency.to_string(number, format, backend, options)
  end

  # For the :currency_medium format only
  defp to_string(number, :currency_long_with_symbol = format, backend, options) do
    Formatter.Currency.to_string(number, format, backend, options)
  end

  # For all other short formats
  defp to_string(number, format, backend, options)
       when is_atom(format) and format in @short_format_styles do
    Formatter.Short.to_string(number, format, backend, options)
  end

  # For executing arbitrary RBNF rules that might exist for a given locale
  defp to_string(_number, format, _backend, %{locale: %{rbnf_locale_name: nil} = locale}) do
    {:error, Cldr.Rbnf.rbnf_rule_error(locale, format)}
  end

  defp to_string(number, format, backend, options) when is_atom(format) do
    with {:ok, module, locale} <- find_rbnf_format_module(options.locale, format, backend) do
      apply(module, format, [number, locale])
    end
  end

  # For all other formats
  defp to_string(number, format, backend, options) when is_binary(format) do
    Formatter.Decimal.to_string(number, format, backend, options)
  end

  # For all other formats.  The known atom-based formats are described
  # above so this must be a format name expected to be defined by a
  # locale but its not there.
  defp to_string(_number, {:error, _} = error, _backend, _options) do
    error
  end

  # Look for the RBNF rule in the given locale or in the
  # root locale (called "und")

  defp find_rbnf_format_module(locale, format, backend) do
    root_locale = Map.put(@root_locale, :backend, backend)

    cond do
      module = find_rbnf_module(locale, format, backend) -> {:ok, module, locale}
      module = find_rbnf_module(root_locale, format, backend) -> {:ok, module, root_locale}
      true ->  {:error, Cldr.Rbnf.rbnf_rule_error(locale, format)}
    end
  end

  defp find_rbnf_module(locale, format, backend) do
    Enum.reduce_while Cldr.Rbnf.categories_for_locale!(locale), nil, fn category, acc ->
      format_module = Module.concat([backend, :Rbnf, category])
      rules = format_module.rule_sets(locale)

      if rules && format in rules do
        {:halt, format_module}
      else
        {:cont, acc}
      end
    end
  end

  defp evaluate_rule(number, module, function, locale, backend) do
    module = Module.concat([backend, :Rbnf, module])
    rule_sets = module.rule_sets(locale)

    if rule_sets && function in rule_sets do
      apply(module, function, [number, locale])
    else
      {:error, Cldr.Rbnf.rbnf_rule_error(locale, function)}
    end
  end

  @doc """
  Formats a number and applies the `:at_least` format for
  a locale and number system.

  ## Arguments

  * `number` is an integer, float or Decimal to be formatted

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  * `options` is a keyword list defining how the number is to be formatted.
    See `Cldr.Number.to_string/3` for a description of the available
    options.

  ## Example

      iex> Cldr.Number.to_at_least_string 1234, TestBackend.Cldr
      {:ok, "1,234+"}

  """
  @spec to_at_least_string(number | Decimal.t(), Cldr.backend(), Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def to_at_least_string(number, backend \\ default_backend(), options \\ [])

  def to_at_least_string(number, options, []) when is_list(options) do
    {backend, options} = Keyword.pop_lazy(options, :backend, &default_backend/0)
    to_at_least_string(number, backend, options)
  end

  def to_at_least_string(number, backend, options) do
    other_format(number, :at_least, backend, options)
  end

  @doc """
  Formats a number and applies the `:at_most` format for
  a locale and number system.

  ## Arguments

  * `number` is an integer, float or Decimal to be formatted

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  * `options` is a keyword list defining how the number is to be formatted.
    See `Cldr.Number.to_string/3` for a description of the available
    options.

  ## Example

      iex> Cldr.Number.to_at_most_string 1234, TestBackend.Cldr
      {:ok, "≤1,234"}

  """
  @spec to_at_most_string(number | Decimal.t(), Cldr.backend(), Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def to_at_most_string(number, backend \\ default_backend(), options \\ [])

  def to_at_most_string(number, options, []) when is_list(options) do
    {backend, options} = Keyword.pop_lazy(options, :backend, &default_backend/0)
    to_at_most_string(number, backend, options)
  end

  def to_at_most_string(number, backend, options) do
    other_format(number, :at_most, backend, options)
  end

  @doc """
  Formats a number and applies the `:approximately` format for
  a locale and number system.

  ## Arguments

  * `number` is an integer, float or Decimal to be formatted

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  * `options` is a keyword list defining how the number is to be formatted.
    See `Cldr.Number.to_string/3` for a description of the available
    options.

  ## Example

      iex> Cldr.Number.to_approx_string 1234, TestBackend.Cldr
      {:ok, "~1,234"}

  """
  @spec to_approx_string(number | Decimal.t(), Cldr.backend(), Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def to_approx_string(number, backend \\ default_backend(), options \\ [])

  def to_approx_string(number, options, []) when is_list(options) do
    {backend, options} = Keyword.pop_lazy(options, :backend, &default_backend/0)
    to_approx_string(number, backend, options)
  end

  def to_approx_string(number, backend, options) do
    other_format(number, :approximately, backend, options)
  end

  @doc """
  Formats the first and last numbers of a range and applies
  the `:range` format for a locale and number system.

  ## Arguments

  * `number` is an integer, float or Decimal to be formatted

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  * `options` is a keyword list defining how the number is to be formatted.
    See `Cldr.Number.to_string/3` for a description of the available
    options.

  ## Example

      iex> Cldr.Number.to_range_string 1234..5678, TestBackend.Cldr
      {:ok, "1,234–5,678"}

  """
  @spec to_range_string(Range.t(), Cldr.backend(), Keyword.t() | map()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def to_range_string(number, backend \\ default_backend(), options \\ [])

  def to_range_string(number, options, []) when is_list(options) do
    {backend, options} = Keyword.pop_lazy(options, :backend, &default_backend/0)
    to_range_string(number, backend, options)
  end

  def to_range_string(range, backend, options) do
    %Range{first: first, last: last} = range

    with {:ok, options} <- Options.validate_options(first, backend, options),
         {:ok, format} <- Options.validate_other_format(:range, backend, options),
         {:ok, first_formatted_number} <- to_string(first, backend, options),
         {:ok, last_formatted_number} <- to_string(last, backend, options) do
      final_format =
        [first_formatted_number, last_formatted_number]
        |> Cldr.Substitution.substitute(format)
        |> :erlang.iolist_to_binary()

      {:ok, final_format}
    end
  end

  @spec other_format(
          number | Decimal.t(),
          :approximately | :at_least | :at_most,
          Cldr.backend(),
          Keyword.t()
        ) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  defp other_format(number, other_format, backend, options) do
    with {:ok, options} <- Options.validate_options(number, backend, options),
         {:ok, format} <- Options.validate_other_format(other_format, backend, options),
         {:ok, formatted_number} <- to_string(number, backend, options) do

      final_format =
        [formatted_number]
        |> Cldr.Substitution.substitute(format)
        |> :erlang.iolist_to_binary()

      {:ok, final_format}
    end
  end

  @doc """
  Converts a number from the latin digits `0..9` into
  another number system.  Returns `{:ok, string}` or
  `{:error, reason}`.

  * `number` is an integer, float.  Decimal is supported only for
    `:numeric` number systems, not `:algorithmic`.  See `Cldr.Number.System.to_system/3`
    for further information.

  * `system` is any number system returned by `Cldr.known_number_systems/0`

  ## Examples

      iex> Cldr.Number.to_number_system 123, :hant, TestBackend.Cldr
      {:ok, "一百二十三"}

      iex> Cldr.Number.to_number_system 123, :hebr, TestBackend.Cldr
      {:ok, "קכ״ג"}

  """
  @spec to_number_system(number, atom, Cldr.backend()) ::
          String.t() | {:error, {module(), String.t()}}

  def to_number_system(number, system, backend \\ default_backend()) do
    Cldr.Number.System.to_system(number, system, backend)
  end

  @doc """
  Converts a number from the latin digits `0..9` into
  another number system. Returns the converted number
  or raises an exception on error.

  * `number` is an integer, float.  Decimal is supported only for
    `:numeric` number systems, not `:algorithmic`.  See `Cldr.Number.System.to_system/3`
    for further information.

  * `system` is any number system returned by `Cldr.Number.System.known_number_systems/0`

  ## Example

      iex> Cldr.Number.to_number_system! 123, :hant, TestBackend.Cldr
      "一百二十三"

  """
  @spec to_number_system!(number, atom, Cldr.backend()) :: String.t() | no_return()

  def to_number_system!(number, system, backend \\ default_backend()) do
    Cldr.Number.System.to_system!(number, system, backend)
  end

  @doc """
  Return the precision (number of digits) of a number

  This function delegates to `Cldr.Digits.number_of_digits/1`

  ## Example

      iex> Cldr.Number.precision 1.234
      4

  """
  defdelegate precision(number), to: Cldr.Digits, as: :number_of_digits

  @doc false
  # TODO remove for Cldr 3.0
  if Code.ensure_loaded?(Cldr) && function_exported?(Cldr, :default_backend!, 0) do
    def default_backend do
      Cldr.default_backend!()
    end
  else
    def default_backend do
      Cldr.default_backend()
    end
  end
end
