defmodule Cldr.Number.Formatter.Short do
  @moduledoc """
  Formats a number according to the locale-specific `:short` formats

  This is best explained by some
  examples:

      iex> Cldr.Number.to_string 123, TestBackend.Cldr, format: :short
      {:ok, "123"}

      iex> Cldr.Number.to_string 1234, TestBackend.Cldr, format: :short
      {:ok, "1K"}

      iex> Cldr.Number.to_string 523456789, TestBackend.Cldr, format: :short
      {:ok, "523M"}

      iex> Cldr.Number.to_string 7234567890, TestBackend.Cldr, format: :short
      {:ok, "7B"}

      iex> Cldr.Number.to_string 7234567890, TestBackend.Cldr, format: :long
      {:ok, "7 billion"}

  These formats are compact representations however they do lose
  precision in the presentation in favour of human readability.

  Note that for a `:currency` short format the number of decimal places
  is retrieved from the currency definition itself.  You can see the difference
  in the following examples:

      iex> Cldr.Number.to_string 1234, TestBackend.Cldr, format: :short, currency: "EUR"
      {:ok, "€1K"}

      iex> Cldr.Number.to_string 1234, TestBackend.Cldr, format: :short, currency: "EUR", fractional_digits: 2
      {:ok, "€1.23K"}

      iex> Cldr.Number.to_string 1234, TestBackend.Cldr, format: :short, currency: "JPY"
      {:ok, "¥1K"}

  **This module is not part of the public API and is subject
  to change at any time.**

  """

  alias Cldr.Math
  alias Cldr.Number.{System, Format, Formatter}
  alias Cldr.Locale
  alias Cldr.LanguageTag
  alias Cldr.Number.Format.Options

  # Notes from Unicode TR35 on formatting short formats:
  #
  # To format a number N, the greatest type less than or equal to N is
  # used, with the appropriate plural category. N is divided by the type, after
  # removing the number of zeros in the pattern, less 1. APIs supporting this
  # format should provide control over the number of significant or fraction
  # digits.
  #
  # If the value is precisely 0, or if the type is less than 1000, then the
  # normal number format pattern for that sort of object is supplied. For
  # example, formatting 1200 would result in “$1.2K”, while 990 would result in
  # simply “$990”.
  #
  # Thus N=12345 matches <pattern type="10000" count="other">00 K</pattern> . N
  # is divided by 1000 (obtained from 10000 after removing "00" and restoring one
  # "0". The result is formatted according to the normal decimal pattern. With no
  # fractional digits, that yields "12 K".

  @spec to_string(Math.number_or_decimal(), atom(), Cldr.backend(), Options.t()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def to_string(number, _style, _backend, _options) when is_binary(number) do
    {:error,
      {
        ArgumentError,
        "Not a number: #{inspect number}. Long and short formats only support number or Decimal arguments"
      }
    }
  end

  def to_string(number, style, backend, options) do
    locale = options.locale || backend.default_locale()

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, number_system} <- System.system_name_from(options.number_system, locale, backend) do
      short_format_string(number, style, locale, number_system, backend, options)
    end
  end

  @spec short_format_string(
          Math.number_or_decimal(),
          atom,
          Locale.locale_name() | LanguageTag.t(),
          System.system_name(),
          Cldr.backend(),
          Options.t()
        ) :: {:ok, String.t()} | {:error, {module(), String.t()}}

  defp short_format_string(number, style, locale, number_system, backend, options) do
    format_rules =
      locale
      |> Format.formats_for!(number_system, backend)
      |> Map.fetch!(style)

    {normalized_number, format} = choose_short_format(number, format_rules, options, backend)
    options = digits(options, options.fractional_digits)
    format = Options.maybe_adjust_currency_symbol(format, options.currency_symbol)

    Formatter.Decimal.to_string(normalized_number, format, backend, options)
  end

  @doc """
  Returns the exponent that will be applied
  when formatting the given number as a short
  format.

  This function is primarily intended to support
  pluralization for compact numbers (numbers
  formatted with the `format: :short` option) since
  some languages pluralize compact numbers differently
  to a fully expressed number.

  Such rules are defined for the locale "fr" from
  CLDR version 38 with the intention that additional
  rules will be added in later versions.

  ## Examples

      iex> Cldr.Number.Formatter.Short.short_format_exponent 1234
      {1000, 1}

      iex> Cldr.Number.Formatter.Short.short_format_exponent 12345
      {10000, 2}

      iex> Cldr.Number.Formatter.Short.short_format_exponent 123456789
      {100000000, 3}

      iex> Cldr.Number.Formatter.Short.short_format_exponent 123456789, locale: "th"
      {100000000, 3}

  """
  def short_format_exponent(number, options \\ []) when is_list(options) do
    with {locale, backend} = Cldr.locale_and_backend_from(options),
         number_system = Keyword.get(options, :number_system, :default),
         {:ok, number_system} <- System.system_name_from(number_system, locale, backend),
         {:ok, all_formats} <- Format.formats_for(locale, number_system, backend) do
      formats = Map.fetch!(all_formats, :decimal_short)
      pluralizer = Module.concat(backend, Number.Cardinal)

      options =
        options
        |> Map.new
        |> Map.put_new(:locale, locale)
        |> Map.put_new(:number_system, number_system)
        |> Map.put_new(:currency, nil)

      case get_short_format_rule(number, formats, options, backend) do
        [range, plural_selectors] ->
          normalized_number = normalise_number(number, range, plural_selectors.other)
          plural_key = pluralization_key(normalized_number, options)
          [_format, number_of_zeros] = pluralizer.pluralize(plural_key, options.locale, plural_selectors)
          {range, number_of_zeros}
        {number, _format} ->
          {number, 0}
      end
    end
  end

  # For short formats the fractional digits should be 0 unless otherwise specified,
  # even for currencies
  defp digits(options, nil) do
    Map.put(options, :fractional_digits, 0)
  end

  defp digits(options, _digits) do
    options
  end

  defp choose_short_format(number, format_rules, options, backend)
      when is_number(number) and number < 0 do
    {number, format} = choose_short_format(abs(number), format_rules, options, backend)
    {number * -1, format}
  end

  defp choose_short_format(%Decimal{sign: -1 = sign} = number, format_rules, options, backend) do
    {normalized_number, format} =
      choose_short_format(Decimal.abs(number), format_rules, options, backend)

    {Decimal.mult(normalized_number, sign), format}
  end

  defp choose_short_format(number, format_rules, options, backend) do
    pluralizer = Module.concat(backend, Number.Cardinal)

    case get_short_format_rule(number, format_rules, options, backend) do
      # Its a short format
      [range, plural_selectors] ->
        normalized_number = normalise_number(number, range, plural_selectors.other)
        plural_key = pluralization_key(normalized_number, options)
        [format, _number_of_zeros] = pluralizer.pluralize(plural_key, options.locale, plural_selectors)
        {normalized_number, format}

      # Its a standard format
      {number, format} ->
        {number, format}
    end
  end

  defp get_short_format_rule(number, _format_rules, options, backend) when is_number(number) and number < 1000 do
    format =
      options.locale
      |> Format.formats_for!(options.number_system, backend)
      |> Map.get(standard_or_currency(options))

    {number, format}
  end

  defp get_short_format_rule(number, format_rules, options, backend) when is_number(number) do
    format_rules
    |> Enum.filter(fn [range, _rules] -> range <= number end)
    |> Enum.reverse()
    |> hd
    |> maybe_get_default_format(number, options, backend)
  end

  defp get_short_format_rule(%Decimal{} = number, format_rules, options, backend) do
    rule =
      number
      |> Decimal.round(0, :floor)
      |> Decimal.to_integer()
      |> get_short_format_rule(format_rules, options, backend)

    case rule do
      {_ignore, format} -> {number, format}
      rule -> rule
    end
  end

  defp maybe_get_default_format([_range, %{other: ["0", _]}], number, options, backend) do
    {_, format} = get_short_format_rule(0, [], options, backend)
    {number, format}
  end

  defp maybe_get_default_format(rule, _number, _options, _backend) do
    rule
  end

  defp standard_or_currency(options) do
    if options.currency do
      :currency
    else
      :standard
    end
  end

  @one_thousand Decimal.new(1000)
  defp normalise_number(%Decimal{} = number, range, number_of_zeros) do
    if Cldr.Decimal.compare(number, @one_thousand) == :lt do
      number
    else
      Decimal.div(number, Decimal.new(adjustment(range, number_of_zeros)))
    end
  end

  defp normalise_number(number, _range, _number_of_zeros) when number < 1000 do
    number
  end

  defp normalise_number(number, _range, ["0", _number_of_zeros]) do
    number
  end

  defp normalise_number(number, range, [_format, number_of_zeros]) do
    number / adjustment(range, number_of_zeros)
  end

  # TODO: We can precompute these at compile time which would
  # save this lookup
  defp adjustment(range, number_of_zeros) when is_integer(number_of_zeros) do
    (range / Math.power_of_10(number_of_zeros - 1))
    |> trunc
  end

  defp adjustment(range, [_, number_of_zeros]) when is_integer(number_of_zeros) do
   adjustment(range, number_of_zeros)
  end

  # The pluralization key has to consider when there is an
  # exact match and when the number would be rounded up. When
  # rounded up it also has to not be an exact match.
  defp pluralization_key(number, options) do
    rounding_mode = Map.get_lazy(options, :rounding_mode, &Cldr.Math.default_rounding_mode/0)

    if (rounded = Cldr.Math.round(number, 0, rounding_mode)) <= number do
      # Rounded number <= number means that the
      # pluralization key is the same integer part
      # so no issue
      number
    else
      # The rounded number is greater than the normalized
      # number so the plural key is different but not exactly
      # equal so we add an offset so pluralization works
      # correctly (we don't want to trigger an exact match;
      # although this relies on exact matches always being integers
      # which as of CLDR39 they are).
      rounded + 0.1
    end
  end
end
