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

    {:ok, currency} = Currency.currency_for_code(options.currency, backend, locale: locale)
    currency_string = cardinal.pluralize(number, locale, currency.count)

    options =
      options
      |> Map.put(:format, :standard)
      |> set_fractional_digits(options.fractional_digits)
      |> Options.resolve_standard_format(backend)

    number_string = Cldr.Number.to_string!(number, backend, options)
    format = cardinal.pluralize(number, locale, formats)

    Substitution.substitute([number_string, currency_string], format)
    |> :erlang.iolist_to_binary()
  end

  defp set_fractional_digits(options, nil) do
    options
    |> Map.put(:fractional_digits, 0)
  end

  defp set_fractional_digits(options, _digits) do
    options
  end
end
