defmodule Cldr.Number.Parser do
  @moduledoc """
  Parse a string into a number and possibly a currency code

  """

  @number_regex ~r/[-+]?[0-9]*\.?[0-9_]+([eE][-+]?[0-9]+)?/

  def split(string, options \\ []) do
    backend = Keyword.get_lazy(options, :backend, &Cldr.default_backend/0)
    locale = Keyword.get_lazy(options, :locale, &backend.get_locale/0)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, symbols} <- Cldr.Number.Symbol.number_symbols_for(locale, backend) do

      normalized = normalize_number_string(string, locale, backend, symbols)
      number_type = Keyword.get(options, :type)

      @number_regex
      |> Regex.split(normalized, include_captures: true, trim: true)
      |> Enum.map(fn element -> parse_number(element, number_type) |> elem(1) end)
    end
  end

  def parse(string, options \\ []) when is_binary(string) and is_list(options) do
    backend = Keyword.get_lazy(options, :backend, &Cldr.default_backend/0)
    locale = Keyword.get_lazy(options, :locale, &backend.get_locale/0)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, symbols} <- Cldr.Number.Symbol.number_symbols_for(locale, backend) do

      string
      |> normalize_number_string(locale, backend, symbols)
      |> parse_number(Keyword.get(options, :type))
    end
  end

  defp parse_number(string, nil) do
    with {:error, string} <- parse_number(string, :integer),
         {:error, string} <- parse_number(string, :float) do
      {:error, string}
    end
  end

  defp parse_number(string, :integer) do
    case Integer.parse(String.trim(string)) do
      {integer, ""} -> {:ok, integer}
      _other -> {:error, string}
    end
  end

  defp parse_number(string, :float) do
    case Float.parse(String.trim(string)) do
      {float, ""} -> {:ok, float}
      _other -> {:error, string}
    end
  end

  defp parse_number(string, :decimal) do
    case Decimal.parse(String.trim(string)) do
      {:ok, decimal} -> {:ok, decimal}
      :error -> {:error, string}
    end
  end

  def resolve_currencies(list, options \\ []) when is_list(list) and is_list(options) do
    Enum.map list, fn
      string when is_binary(string) ->
        case resolve_currency(string, options) do
          {:error, _} -> string
          currency -> currency
        end

      other -> other
    end
  end

  def resolve_currency(string, options \\ []) do
    backend = Keyword.get_lazy(options, :backend, &Cldr.default_backend/0)
    locale = Keyword.get_lazy(options, :locale, &backend.get_locale/0)
    string = String.trim(string)

    {only_filter, options} =
      Keyword.pop(options, :only, Keyword.get(options, :currency_filter, [:all]))

    {except_filter, options} = Keyword.pop(options, :except, [])
    {fuzzy, _options} = Keyword.pop(options, :fuzzy, nil)

    with {:ok, locale} <- backend.validate_locale(locale),
         {:ok, currency_strings} <-
           Cldr.Currency.currency_strings(locale, backend, only_filter, except_filter),
         {:ok, currency} <-
           find_currency(currency_strings, string, fuzzy) do
      currency
    end
  end

  defp normalize_number_string(string, locale, backend, symbols) do
    string
    |> String.replace("_", "")
    |> backend.normalize_lenient_parse(:number, locale)
    |> backend.normalize_lenient_parse(:general, locale)
    |> String.replace(symbols.latn.group, "")
    |> String.replace(symbols.latn.decimal, ".")
    |> String.replace("_", "-")
  end

  defp find_currency(currency_strings, currency, nil) do
    canonical_currency = String.downcase(currency)

    case Map.get(currency_strings, canonical_currency) do
      nil ->
        {:error, unknown_currency_error(currency)}

      currency ->
        {:ok, currency}
    end
  end

  defp find_currency(currency_strings, currency, fuzzy)
       when is_float(fuzzy) and fuzzy > 0.0 and fuzzy <= 1.0 do
    canonical_currency = String.downcase(currency)

    {distance, currency_code} =
      currency_strings
      |> Enum.map(fn {k, v} -> {String.jaro_distance(k, canonical_currency), v} end)
      |> Enum.sort(fn {k1, _v1}, {k2, _v2} -> k1 > k2 end)
      |> hd

    if distance >= fuzzy do
      {:ok, currency_code}
    else
      {:error, unknown_currency_error(currency)}
    end
  end

  defp find_currency(_currency_strings, _currency, fuzzy) do
    {:error,
     {
       ArgumentError,
       "option :fuzzy must be a number > 0.0 and <= 1.0. Found #{inspect(fuzzy)}"
     }}
  end

  defp unknown_currency_error(currency) do
    {Money.UnknownCurrencyError, "The currency #{inspect(currency)} is unknown or not supported"}
  end
end