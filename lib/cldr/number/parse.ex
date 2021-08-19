defmodule Cldr.Number.Parser do
  @moduledoc """
  Functions for parsing numbers and currencies from
  a string.

  """

  @number_format "[-+]?[0-9]([0-9_]|[,](?=[0-9]))*(\\.?[0-9_]+([eE][-+]?[0-9]+)?)?"

  @doc """
  Scans a string in a locale-aware manner and returns
  a list of strings and numbers.

  ## Arguments

  * `string` is any `String.t`

  * `options` is a keyword list of options

  ## Options

  * `:number` is one of `:integer`, `:float`,
    `:decimal` or `nil`. The default is `nil`
    meaning that the type auto-detected as either
    an `integer` or a `float`.

  * `:backend` is any module that includes `use Cldr`
    and is therefore a CLDR backend module. The default
    is `Cldr.default_backend!/0`.

  * `:locale` is any locale returned by `Cldr.known_locale_names/1`
    or a `t:Cldr.LanguageTag`. The default is `options[:backend].get_locale/1`.

  ## Returns

  * A list of strings and numbers

  ## Notes

  Number parsing is performed by `Cldr.Number.Parser.parse/2`
  and any options provided are passed to that function.

  ## Examples

      iex> Cldr.Number.Parser.scan("£1_000_000.34")
      ["£", 1000000.34]

      iex> Cldr.Number.Parser.scan("I want £1_000_000 dollars")
      ["I want £", 1000000, " dollars"]

      iex> Cldr.Number.Parser.scan("The prize is 23")
      ["The prize is ", 23]

      iex> Cldr.Number.Parser.scan("The lottery number is 23 for the next draw")
      ["The lottery number is ", 23, " for the next draw"]

      iex> Cldr.Number.Parser.scan("The loss is -1.000 euros", locale: "de", number: :integer)
      ["The loss is ", -1000, " euros"]

      iex> Cldr.Number.Parser.scan "1kg"
      [1, "kg"]

      iex> Cldr.Number.Parser.scan "A number is the arab script ١٢٣٤٥", locale: "ar"
      ["A number is the arab script ", 12345]

  """
  @spec scan(String.t(), Keyword.t()) ::
    list(String.t() | integer() | float() | Decimal.t()) |
    {:error, {module(), String.t()}}

  def scan(string, options \\ []) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, symbols} <- Cldr.Number.Symbol.number_symbols_for(locale, backend),
         {:ok, number_system} <- digits_number_system_from(locale) do

      symbols =
        symbols_for_number_system(symbols, number_system)

      scanner =
        @number_format
        |> localize_format_string(locale, backend, symbols)
        |> Regex.compile!([:unicode])

      normalized_string =
        transliterate(string, number_system, :latn, backend)

      scanner
      |> Regex.split(normalized_string, include_captures: true, trim: true)
      |> Enum.map(&parse_element(&1, options))
    end
  end

  defp parse_element(element, options) do
    case parse(element, options) do
      {:ok, number} -> number
      {:error, _} -> element
    end
  end

  @doc """
  Parse a string in a locale-aware manner and return
  a number.

  ## Arguments

  * `string` is any `t:String`

  * `options` is a keyword list of options

  ## Options

  * `:number` is one of `:integer`, `:float`,
    `:decimal` or `nil`. The default is `nil`
    meaning that the type auto-detected as either
    an `integer` or a `float`.

  * `:backend` is any module that includes `use Cldr`
    and is therefore a CLDR backend module. The default
    is `Cldr.default_backend/0`.

  * `:locale` is any locale returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag.t`. The default is `options[:backend].get_locale/1`.

  ## Returns

  * A number of the requested or default type or

  * `{:error, {exception, message}}` if no number could be determined

  ## Notes

  This function parses a string to return a number but
  in a locale-aware manner. It will normalise digits,
  grouping characters and decimal separators.

  It will transliterate digits that are in the
  number system of the specific locale. For example, if
  the locale is `th` (Thailand), then Thai digits are
  transliterated to the Latin script before parsing.

  Some number systems do not have decimal digits and in this
  case an error will be returned, rather than continue
  parsing and return misleading results.

  It also caters for different forms of
  the `+` and `-` symbols that appear in Unicode and
  strips any `_` characters that might be used for
  formatting in a string.

  It then parses the number using the Elixir standard
  library functions.

  If the option `:number` is used and the parsed number
  cannot be coerced to this type without losing precision
  then an error is returned.

  ## Examples

      iex> Cldr.Number.Parser.parse("＋1.000,34", locale: "de")
      {:ok, 1000.34}

      iex> Cldr.Number.Parser.parse("-1_000_000.34")
      {:ok, -1000000.34}

      iex> Cldr.Number.Parser.parse("1.000", locale: "de", number: :integer)
      {:ok, 1000}

      iex> Cldr.Number.Parser.parse "١٢٣٤٥", locale: "ar"
      {:ok, 12345}

      # 1_000.34 cannot be coerced into an integer
      # without precision loss so an error is returned.
      iex> Cldr.Number.Parser.parse("＋1.000,34", locale: "de", number: :integer)
      {:error,
        {Cldr.Number.ParseError,
         "The string \\"＋1.000,34\\" could not be parsed as a number"}}

      iex> Cldr.Number.Parser.parse "一万二千三百四十五", locale: "ja-u-nu-jpan"
      {:error,
       {Cldr.UnknownNumberSystemError,
        "The number system :jpan is not known or does not have digits"}}

  """
  @spec parse(String.t(), Keyword.t()) ::
    {:ok, integer() | float() | Decimal.t()} |
    {:error, {module(), String.t()}}

  def parse(string, options \\ []) when is_binary(string) and is_list(options) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, symbols} <- Cldr.Number.Symbol.number_symbols_for(locale, backend),
         {:ok, number_system} <- digits_number_system_from(locale) do

      symbols =
        symbols_for_number_system(symbols, number_system)

      normalized_string =
        string
        |> transliterate(number_system, :latn, backend)
        |> normalize_number_string(locale, backend, symbols)
        |> String.trim()

      case parse_number(normalized_string, Keyword.get(options, :number)) do
        {:error, _} -> {:error, parse_error(string)}
        success -> success
      end
    end
  end

  defp parse_number(string, nil) do
    with {:error, string} <- parse_number(string, :integer),
         {:error, string} <- parse_number(string, :float) do
      {:error, string}
    end
  end

  defp parse_number(string, :integer) do
    case Integer.parse(string) do
      {integer, ""} -> {:ok, integer}
      _other -> {:error, string}
    end
  end

  defp parse_number(string, :float) do
    case Float.parse(string) do
      {float, ""} -> {:ok, float}
      _other -> {:error, string}
    end
  end

  defp parse_number(string, :decimal) do
    case Cldr.Decimal.parse(string) do
      {:error, ""} -> {:error, string}
      {decimal, ""} -> {:ok, decimal}
      _other -> {:error, string}
    end
  end


  @doc """
  Resolve curencies from strings within
  a list.

  Currencies can be identified at the
  beginning and/or the end of a string.

  ## Arguments

  * `list` is any list in which currency
    names and symbols are expected

  * `options` is a keyword list of options

  ## Options

  * `:backend` is any module() that includes `use Cldr` and therefore
    is a `Cldr` backend module(). The default is `Cldr.default_backend!/0`

  * `:locale` is any valid locale returned by `Cldr.known_locale_names/1`
    or a `t:Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`
    The default is `options[:backend].get_locale()`

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

      iex> Cldr.Number.Parser.scan("100 US dollars")
      ...> |> Cldr.Number.Parser.resolve_currencies
      [100, :USD]

      iex> Cldr.Number.Parser.scan("100 eurosports")
      ...> |> Cldr.Number.Parser.resolve_currencies(fuzzy: 0.8)
      [100, :EUR]

      iex> Cldr.Number.Parser.scan("100 dollars des États-Unis")
      ...> |> Cldr.Number.Parser.resolve_currencies(locale: "fr")
      [100, :USD]

  """
  @spec resolve_currencies([String.t(), ...], Keyword.t()) ::
    list(Cldr.Currency.code() | String.t())

  def resolve_currencies(list, options \\ []) when is_list(list) and is_list(options) do
    Enum.map(list, fn
      string when is_binary(string) ->
        case resolve_currency(string, options) do
          {:error, _} -> string
          currency -> currency
        end

      other -> other
    end)
    |> List.flatten()
  end

  @doc """
  Resolve a currency from the beginning
  and/or the end of a string

  ## Arguments

  * `list` is any list in which currency
    names and symbols are expected

  * `options` is a keyword list of options

  ## Options

  * `:backend` is any module() that includes `use Cldr` and therefore
    is a `Cldr` backend module(). The default is `Cldr.default_backend!/0`

  * `:locale` is any valid locale returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`
    The default is `options[:backend].get_locale()`

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

  * An ISO417 currency code as an atom or

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

      iex> Cldr.Number.Parser.resolve_currency("US dollars")
      :USD

      iex> Cldr.Number.Parser.resolve_currency("100 eurosports", fuzzy: 0.75)
      :EUR

      iex> Cldr.Number.Parser.resolve_currency("dollars des États-Unis", locale: "fr")
      :USD

      iex> Cldr.Number.Parser.resolve_currency("not a known currency", locale: "fr")
      {:error,
       {Cldr.UnknownCurrencyError,
        "The currency \\"not a known currency\\" is unknown or not supported"}}

  """
  @spec resolve_currency(String.t(), Keyword.t()) ::
    Cldr.Currency.code() | list(Cldr.Currency.code() | String.t()) |
    {:error, {module(), String.t()}}

  def resolve_currency(string, options \\ []) do
    {locale, backend} = Cldr.locale_and_backend_from(options)

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

  # Replace localised symbols with canonical forms
  defp normalize_number_string(string, locale, backend, symbols) do
    string
    |> String.replace("_", "")
    |> backend.normalize_lenient_parse(:number, locale)
    |> backend.normalize_lenient_parse(:general, locale)
    |> String.replace(symbols.group, "")
    |> String.replace(" ", "")
    |> String.replace(symbols.decimal, ".")
    |> String.replace("_", "-")
  end

  defp transliterate(string, from, to, backend) do
    module = Module.concat(backend, Number.Transliterate)

    case module.transliterate_digits(string, from, to) do
      {:error, _} -> string
      string -> string
    end
  end

  defp digits_number_system_from(locale) do
    number_system = Cldr.Number.System.number_system_from_locale(locale)

    with {:ok, _digits} <- Cldr.Number.System.number_system_digits(number_system) do
      {:ok, number_system}
    end
  end

  defp symbols_for_number_system(symbols, number_system) do
    Map.fetch!(symbols, number_system) || Map.fetch!(symbols, :latn)
  end

  # Replace canonical forms with localised symbols
  defp localize_format_string(string, locale, backend, symbols) do
    parse_map = backend.lenient_parse_map(:number, locale.cldr_locale_name)
    plus_matchers = Map.get(parse_map, "+").source |> String.replace(["[", "]"], "")
    minus_matchers = Map.get(parse_map, "_").source |> String.replace(["[", "]"], "")
    grouping_matchers = Map.get(parse_map, ",").source |> String.replace(["[", "]"], "")

    string
    |> String.replace("[-+]", "[" <> plus_matchers <> minus_matchers <> "]")
    |> String.replace(",", grouping_matchers <> maybe_add_space(symbols.group))
    |> String.replace("\\.", "\\" <> symbols.decimal)
  end

  # If the grouping symbol is a pop space then
  # also allow normal space as a group symbol when parsing
  @pop_space " " # 0x202c
  @space " " # 0x20

  defp maybe_add_space(@pop_space), do: @pop_space <> @space
  defp maybe_add_space(other), do: other

  # Find a currency at the beginnig and end of a string, but ignore
  # any whitespace found at the start or end. Leading and trailing
  # whitespace is preserved if there is no currency found so trimming
  # can only be applied when required, not up front.

  defp find_currency(currency_strings, currency, nil) do
    search =
      currency
      |> String.downcase()

    if currency_code = Map.get(currency_strings, String.trim(search)) do
      currency_code
    else
      [starting_code, remainder] = starting_currency(currency_strings, search)
      [remainder, ending_code] = ending_currency(currency_strings, remainder)
      if starting_code == "" && ending_code == "" do
        {:error, unknown_currency_error(search)}
      else
        {:ok, Enum.reject([starting_code, remainder, ending_code], &(&1 == ""))}
      end
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
      currency_code
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

  def starting_currency(currency_strings, search) do
    trimmed = String.trim_leading(search)
    case starts_with(currency_strings, trimmed) do
      [] ->
        ["", search]
      list ->
        {currency_string, currency_code} = longest_currency_match(list)
        ["", remainder] = String.split(trimmed, currency_string, parts: 2)
        [currency_code, remainder]
    end
  end

  def ending_currency(currency_strings, search) do
    trimmed = String.trim_trailing(search)
    case ends_with(currency_strings, trimmed) do
      [] ->
        [search, ""]
      list ->
        {currency_string, currency_code} = longest_currency_match(list)
        [remainder, ""] = String.split(trimmed, currency_string, parts: 2)
        [remainder, currency_code]
    end
  end

  defp starts_with(strings, search) do
    Enum.filter(strings, &String.starts_with?(search, elem(&1, 0)))
  end

  defp ends_with(strings, search) do
    Enum.filter(strings, &String.ends_with?(search, elem(&1, 0)))
  end

  defp longest_currency_match(currencies) do
    currencies
    |> Enum.sort(fn a, b -> String.length(elem(a, 0)) > String.length(elem(b, 0)) end)
    |> hd
  end

  defp unknown_currency_error(currency) do
    {Cldr.UnknownCurrencyError, "The currency #{inspect(currency)} is unknown or not supported"}
  end

  defp parse_error(string) do
    {Cldr.Number.ParseError, "The string #{inspect string} could not be parsed as a number"}
  end

end