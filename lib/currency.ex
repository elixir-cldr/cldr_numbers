defmodule Cldr.Currency do
  @moduledoc """
  Defines a currency structure and a set of functions to manage the validity of a currency code
  and to return metadata for currencies.
  """
  require Cldr
  alias Cldr.Locale
  alias Cldr.LanguageTag

  @type format :: :standard |
    :accounting |
    :short |
    :long |
    :percent |
    :scientific

  @type code :: String.t

  @type t :: %__MODULE__{
    code: code,
    name: String.t,
    tender: boolean,
    symbol: String.t,
    digits: pos_integer,
    rounding: pos_integer,
    narrow_symbol: String.t,
    cash_digits: pos_integer,
    cash_rounding: pos_integer,
    count: %{}
  }

  defstruct [
    :code,
    :name,
    :symbol,
    :narrow_symbol,
    :digits,
    :rounding,
    :cash_digits,
    :cash_rounding,
    :tender,
    :count]

  @doc """
  Returns a `Currency` struct created from the arguments.

  * `currency` is a custom currency code of a format defined in ISO4217

  * `options` is a map of options representing the optional elements of the `%Currency{}` struct

  ## Example

      iex> Cldr.Currency.new(:XAA)
      {:ok,
       %Cldr.Currency{cash_digits: 0, cash_rounding: 0, code: :XAA, count: nil,
        digits: 0, name: "", narrow_symbol: nil, rounding: 0, symbol: "",
        tender: false}}

      iex> Cldr.Currency.new(:XAA, name: "Custom Name")
      {:ok,
       %Cldr.Currency{cash_digits: 0, cash_rounding: 0, code: :XAA, count: nil,
        digits: 0, name: "Custom Name", narrow_symbol: nil, rounding: 0, symbol: "",
        tender: false}}

      iex> Cldr.Currency.new(:XBC)
      {:error, "Currency :XBC is already defined"}

  """
  @spec new(binary | atom, map | list) :: t | {:error, binary}
  @currency_defaults %{
    name: "",
    symbol: "",
    narrow_symbol: nil,
    digits: 0,
    rounding: 0,
    cash_digits: 0,
    cash_rounding: 0,
    tender: false
  }
  def new(currency, options \\ [])

  def new(currency, options) when is_list(options) do
    new(currency, Enum.into(options, %{}))
  end

  def new(currency, options) when is_map(options) do
    with false <- known_currency?(currency),
         {:ok, currency_code} <- make_currency_code(currency)
    do
      options = @currency_defaults
      |> Map.merge(options)
      |> Map.merge(%{code: currency_code})

      {:ok, struct(__MODULE__, options)}
    else
      true -> {:error, "Currency #{inspect currency} is already defined"}
      error -> error
    end
  end

  @doc """
  Returns the appropriate currency display name for the `currency`, based
  on the plural rules in effect for the `locale`.

  * `number` is an integer, float or `Decimal`

  * `currency` is any currency returned by `Cldr.Currency.known_currencies/0`

  * `options` is a keyword list of options
    * `:locale` is any locale returned by `Cldr.Locale.new!/1`.  The
    default is `Cldr.get_current_locale/0`

  ## Examples

      iex> Cldr.Currency.pluralize 1, :USD
      "US dollar"

      iex> Cldr.Currency.pluralize 3, :USD
      "US dollars"

      iex> Cldr.Currency.pluralize 12, :USD, locale: Cldr.Locale.new!("zh")
      "美元"

      iex> Cldr.Currency.pluralize 12, :USD, locale: Cldr.Locale.new!("fr")
      "dollars des États-Unis"

      iex> Cldr.Currency.pluralize 1, :USD, locale: Cldr.Locale.new!("fr")
      "dollar des États-Unis"

  """
  def pluralize(number, currency, options \\ []) do
    default_options = [locale: Cldr.get_current_locale()]
    options = Keyword.merge(default_options, options)
    locale = options[:locale]

    with \
      {:ok, currency_code} <- validate_currency_code(currency),
      {:ok, locale} <- Cldr.validate_locale(locale)
    do
      currency_data = for_code(currency_code, locale)
      counts = Map.get(currency_data, :count)
      Cldr.Number.Cardinal.pluralize(number, locale, counts)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns a list of all known currency codes.

  ## Example

      iex> Cldr.Currency.known_currencies |> Enum.count
      300

  """
  def known_currencies do
    Cldr.known_currencies
  end

  @doc """
  Returns a boolean indicating if the supplied currency code is known.

  * `currency_code` is a `binary` or `atom` representing an ISO4217
  currency code

  * `custom_currencies` is an optional list of custom currencies created by the
  `Cldr.Currency.new/2` function

  ## Examples

      iex> Cldr.Currency.known_currency? "AUD"
      true

      iex> Cldr.Currency.known_currency? "GGG"
      false

      iex> Cldr.Currency.known_currency? :XCV
      false

      iex> Cldr.Currency.known_currency? :XCV, [%Cldr.Currency{code: :XCV}]
      true

  """
  @spec known_currency?(code, [__MODULE__, ...]) :: boolean
  def known_currency?(currency_code, custom_currencies \\ [])
  def known_currency?(currency_code, custom_currencies) when is_binary(currency_code) do
    case code_atom = normalize_currency_code(currency_code) do
      {:error, {_exception, _message}} -> false
      _ -> known_currency?(code_atom, custom_currencies)
    end
  end

  def known_currency?(currency_code, custom_currencies)
  when is_atom(currency_code) and is_list(custom_currencies) do
    !!(Enum.find(known_currencies(), &(&1 == currency_code)) ||
       Enum.find(custom_currencies, &(&1.code == currency_code)))
  end

  @doc """
  Returns a valid normalized ISO4217 format custom currency code or an error.

  Currency codes conform to the ISO4217 standard which means that any
  custom currency code must start with an "X" followed by two alphabetic
  characters.

  ## Examples

      iex> Cldr.Currency.make_currency_code("xzz")
      {:ok, :XZZ}

      iex> Cldr.Currency.make_currency_code("aaa")
      {:error,
       "Invalid currency code \\"AAA\\".  Currency codes must start with 'X' followed by 2 alphabetic characters only."}

  Note that since this function creates atoms, its important that this
  function not be called with arbitrary user input since that risks
  overflowing the atom table.
  """
  @valid_currency_code Regex.compile!("^X[A-Z]{2}$")
  @spec make_currency_code(binary | atom) :: {:ok, atom} | {:error, binary}
  def make_currency_code(code) do
    currency_code = code
    |> to_string
    |> String.upcase

    if String.match?(currency_code, @valid_currency_code) do
      {:ok, String.to_atom(currency_code)}
    else
      {:error, "Invalid currency code #{inspect currency_code}.  " <>
        "Currency codes must start with 'X' followed by 2 alphabetic characters only."}
    end
  end

  @doc """
  Returns the currency metadata for the requested currency code.

  * `currency_code` is a `binary` or `atom` representation of an ISO 4217 currency code.

  ## Examples

      iex> Cldr.Currency.for_code("AUD")
      %Cldr.Currency{cash_digits: 2, cash_rounding: 0, code: "AUD",
      count: %{one: "Australian dollar", other: "Australian dollars"},
      digits: 2, name: "Australian Dollar", narrow_symbol: "$",
      rounding: 0, symbol: "A$", tender: true}

      iex> Cldr.Currency.for_code("THB")
      %Cldr.Currency{cash_digits: 2, cash_rounding: 0, code: "THB",
      count: %{one: "Thai baht", other: "Thai baht"}, digits: 2,
      name: "Thai Baht", narrow_symbol: "฿", rounding: 0, symbol: "THB",
      tender: true}

  """
  @spec for_code(code, LanguageTag.t) :: %{}
  def for_code(currency_code, locale \\ Cldr.get_current_locale()) do
    with \
      {:ok, code} <- Cldr.validate_currency(currency_code),
      {:ok, locale} <- Cldr.validate_locale(locale)
    do
      locale
      |> for_locale
      |> Map.get(code)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns the currency metadata for a locale.
  """
  @spec for_locale(Locale.name | LanguageTag.t) :: Map.t
  def for_locale(locale \\ Cldr.get_current_locale())

  for locale_name <- Cldr.Config.known_locale_names() do
    currencies =
      locale_name
      |> Cldr.Config.get_locale
      |> Map.get(:currencies)
      |> Enum.map(fn {k, v} -> {k, struct(@struct, v)} end)

    def for_locale(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
      unquote(Macro.escape(currencies))
      |> Enum.into(%{})
    end
  end

  def for_locale(locale_name) when is_binary(locale_name) do
    case Locale.canonical_language_tag(locale_name) do
      {:ok, locale} -> for_locale(locale)
      {:error, reason} -> {:error, reason}
    end
  end

  def for_locale(locale) do
    {:error, Locale.locale_error(locale)}
  end

end
