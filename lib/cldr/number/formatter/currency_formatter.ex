defmodule Cldr.Number.Formatter.Currency do
  @moduledoc """
  Number formatter for the `:currency` `:long` format.

  This formatter implements formatting a currency in a long form. This
  is not the same as decimal formatting with a currency placeholder.

  To explain the difference, look at the following examples:

      iex> Cldr.Number.to_string 123, TestBackend.Cldr, format: :currency, currency: "USD"
      {:ok, "$123.00"}

      iex> Cldr.Number.to_string 123, TestBackend.Cldr, format: :long, currency: "USD"
      {:ok, "123 US dollars"}

  In the first example the format is defined by a decimal mask. In this example
  the format mask comes from:

      iex> {:ok, formats} = Cldr.Number.Format.all_formats_for("en", TestBackend.Cldr)
      ...> formats.latn.currency
      "¤#,##0.00"

  In the second example we are using a format that combines the number with
  a language translation of the currency name.  In this example the format
  comes from:

      iex> {:ok, formats} = Cldr.Number.Format.all_formats_for("en", TestBackend.Cldr)
      ...> formats.latn.currency_long
      %{one: [0, " ", 1], other: [0, " ", 1]}

  Where "{0}" is replaced with the number formatted using the `:standard`
  decimal format and "{1} is replaced with locale-specific name of the
  currency adjusted for the locales plural rules."

  **This module is not part of the public API and is subject
  to change at any time.**

  """

  alias Cldr.Number.{Format, System}
  alias Cldr.{Substitution, Currency}
  alias Cldr.Number.Format.Options
  alias Cldr.Number.Formatter.Decimal

  import Cldr.Number.Formatter.Decimal, only: [is_currency: 1]
  import DigitalToken, only: [is_digital_token: 1]

  @doc false
  def to_string(number, _format, _backend, _options) when is_binary(number) do
    {:error,
      {
        ArgumentError,
        "Not a number: #{inspect number}. Currency long formats only support number or Decimal arguments"
      }
    }
  end

  # The format :currency_medium is a composition of :currency_long
  # and the default :currency format.

  def to_string(number, :currency_long_with_symbol, backend, options) do
    decimal_options = decimal_options(options, backend)
    decimal_format = decimal_options.format

    number
    |> Cldr.Number.to_string!(backend, long_options(options))
    |> Decimal.to_string(decimal_format, backend, decimal_options)
  end

  def to_string(number, :currency_long, backend, options) do
    locale = options.locale
    number_system = System.system_name_from!(options.number_system, locale, backend)
    cardinal = Module.concat(backend, Number.Cardinal)

    if !(formats = Format.formats_for!(locale, number_system, backend).currency_long) do
      raise ArgumentError,
        message:
          "No :currency_long format known for " <>
            "locale #{inspect(locale)} and number system #{inspect(number_system)}."
    end

    options =
      options
      |> Map.put(:format, :standard)
      |> set_fractional_digits(options.currency, options.fractional_digits)
      |> Options.resolve_standard_format(backend)

    currency_string = currency_string(number, options.currency, cardinal, locale, backend)
    number_string = Cldr.Number.to_string!(number, backend, options)
    format = cardinal.pluralize(number, locale, formats)

    Substitution.substitute([number_string, currency_string], format)
    |> :erlang.iolist_to_binary()
  end

  defp currency_string(number, currency, cardinal, locale, backend) when is_currency(currency) do
    {:ok, currency} = Currency.currency_for_code(currency, backend, locale: locale)
    cardinal.pluralize(number, locale, currency.count)
  end

  defp currency_string(_number, currency, _cardinal, _locale, _backend) when is_digital_token(currency) do
    {:ok, currency_string} = DigitalToken.long_name(currency)
    currency_string
  end

  defp set_fractional_digits(options, currency, nil) when is_currency(currency) do
    Map.put(options, :fractional_digits, 0)
  end

  defp set_fractional_digits(options, _currency, _digits) do
    options
  end

  defp long_options(options) do
    options
    |> Map.put(:format, :decimal_long)
    |> Map.put(:currency, nil)
  end

  defp decimal_options(options, backend) do
    currency_format = Currency.currency_format_from_locale(options.locale)
    options = Map.put(options, :format, currency_format)
    Options.resolve_standard_format(options, backend)
  end

end
