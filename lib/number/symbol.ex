defmodule Cldr.Number.Symbol do
  @moduledoc """
  Functions to manage the symbol definitions for a locale and
  number system.
  """

  require Cldr
  alias Cldr.Number
  alias Cldr.Locale
  alias Cldr.LanguageTag

  defstruct [
    :decimal,
    :group,
    :exponential,
    :infinity,
    :list,
    :minus_sign,
    :nan,
    :per_mille,
    :percent_sign,
    :plus_sign,
    :superscripting_exponent,
    :time_separator
  ]

  @doc """
  Returns a map of `Cldr.Number.Symbol.t` structs of the number symbols for each
  of the number systems of a locale.

  ## Options

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`.  The
    default is `Cldr.get_current_locale/0`.

  ## Example:

      iex> Cldr.Number.Symbol.number_symbols_for("th")
      {:ok, %{
         latn: %Cldr.Number.Symbol{
           decimal: ".",
           exponential: "E",
           group: ",",
           infinity: "∞",
           list: ";",
           minus_sign: "-",
           nan: "NaN",
           per_mille: "‰",
           percent_sign: "%",
           plus_sign: "+",
           superscripting_exponent: "×",
           time_separator: ":"
         },
         thai: %Cldr.Number.Symbol{
           decimal: ".",
           exponential: "E",
           group: ",",
           infinity: "∞",
           list: ";",
           minus_sign: "-",
           nan: "NaN",
           per_mille: "‰",
           percent_sign: "%",
           plus_sign: "+",
           superscripting_exponent: "×",
           time_separator: ":"
         }
       }}

  """
  @spec number_symbols_for(LanguageTag.t() | Locale.locale_name()) :: Keyword.t()
  def number_symbols_for(locale \\ Cldr.get_current_locale())

  for locale <- Cldr.Config.known_locale_names() do
    symbols =
      locale
      |> Cldr.Config.get_locale()
      |> Map.get(:number_symbols)
      |> Enum.map(fn
        {k, nil} -> {k, nil}
        {k, v} -> {k, struct(@struct, v)}
      end)
      |> Enum.into(%{})

    def number_symbols_for(%LanguageTag{cldr_locale_name: unquote(locale)}) do
      {:ok, unquote(Macro.escape(symbols))}
    end
  end

  def number_symbols_for(locale_name) when is_binary(locale_name) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name) do
      number_symbols_for(locale)
    end
  end

  def number_symbols_for(locale) do
    {:error, Locale.locale_error(locale)}
  end

  @doc """
  Returns the number sysbols for a specific locale and number system.

  ## Options

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`.  The
    default is `Cldr.get_current_locale/0`.

  * `number_system` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  ## Example

      iex> Cldr.Number.Symbol.number_symbols_for("th", "thai")
      {:ok, %Cldr.Number.Symbol{
         decimal: ".",
         exponential: "E",
         group: ",",
         infinity: "∞",
         list: ";",
         minus_sign: "-",
         nan: "NaN",
         per_mille: "‰",
         percent_sign: "%",
         plus_sign: "+",
         superscripting_exponent: "×",
         time_separator: ":"
       }}

  """
  @spec number_symbols_for(LanguageTag.t() | Locale.locale_name(), System.system_name()) ::
          {:ok, Map.t()} | {:error, {Cldr.NoNumberSymbols, String.t()}}

  def number_symbols_for(%LanguageTag{} = locale, number_system) do
    with {:ok, system_name} <- Number.System.system_name_from(number_system, locale),
         {:ok, symbols} <- number_symbols_for(locale) do
      symbols
      |> Map.get(system_name)
      |> symbols_return(locale, number_system)
    end
  end

  def number_symbols_for(locale_name, number_system) when is_binary(locale_name) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name) do
      number_symbols_for(locale, number_system)
    end
  end

  defp symbols_return(nil, locale, number_system) do
    {
      :error,
      {
        Cldr.NoNumberSymbols,
        "The locale #{inspect(locale)} does not have " <>
          "any symbols for number system #{inspect(number_system)}"
      }
    }
  end

  defp symbols_return(symbols, _locale, _number_system) do
    {:ok, symbols}
  end
end
