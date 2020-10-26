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
  precision in the presentation in favour of human readibility.

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
    case Format.formats_for(locale, number_system, backend) do
      {:ok, formats} ->
        formats = Map.get(formats, style)

        {number, format} =
          case choose_short_format(number, formats, backend, options) do
            {_range, ["0", _number_of_zeroes]} ->
              {_, format} = choose_short_format(0, formats, backend, options)
              {number, format}

            {range, [format, number_of_zeros]} ->
              {normalise_number(number, range, number_of_zeros), format}

            {_range, format} ->
              {number, format}
          end

        options = digits(options, options.fractional_digits)
        format = Options.maybe_adjust_currency_symbol(format, options.currency_symbol)

        Formatter.Decimal.to_string(number, format, backend, options)

      {:error, _} = error ->
        error
    end
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

      options =
        options
        |> Map.new
        |> Map.put_new(:locale, locale)
        |> Map.put_new(:number_system, number_system)
        |> Map.put_new(:currency, nil)

      case choose_short_format(number, formats, backend, options) do
        {range, [_, exponent]} -> {range, exponent}
        {range, _other} -> {range, 0}
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

  defp choose_short_format(number, _rules, backend, options)
       when is_number(number) and number < 1000 do
    format =
      options.locale
      |> Format.formats_for!(options.number_system, backend)
      |> Map.get(standard_or_currency(options))

    {number, format}
  end

  defp choose_short_format(number, rules, backend, options) when is_number(number) do
    [range, rule] =
      rules
      |> Enum.filter(fn [range, _rules] -> range <= number end)
      |> Enum.reverse()
      |> hd

    mod =
      number
      |> trunc
      |> rem(range)

    {range, Module.concat(backend, Number.Cardinal).pluralize(mod, options.locale, rule)}
  end

  defp choose_short_format(%Decimal{} = number, rules, backend, options) do
    number
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
    |> choose_short_format(rules, backend, options)
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

  defp normalise_number(number, range, number_of_zeros) do
    number / adjustment(range, number_of_zeros)
  end

  # TODO: We can precompute these at compile time which would
  # save this lookup
  defp adjustment(range, number_of_zeros) do
    (range / Math.power_of_10(number_of_zeros - 1))
    |> trunc
  end
end
