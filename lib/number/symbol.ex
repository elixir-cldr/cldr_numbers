defmodule Cldr.Number.Symbol do
  @moduledoc """
  Functions to manage the symbol definitions for a locale and
  number system.
  """

  require Cldr
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

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`.  The
    default is `Cldr.get_current_locale/1`.

  ## Example:

      iex> Cldr.Number.Symbol.number_symbols_for("th", TestBackend.Cldr)
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
  @spec number_symbols_for(LanguageTag.t() | Locale.locale_name(), Cldr.backend()) :: Keyword.t()
  def number_symbols_for(locale, backend) do
    Module.concat(backend, Number.Symbol).number_symbols_for(locale)
  end

  @doc """
  Returns the number sysbols for a specific locale and number system.

  ## Options

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`.  The
    default is `Cldr.get_current_locale/1`.

  * `number_system` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  ## Example

      iex> Cldr.Number.Symbol.number_symbols_for("th", "thai", TestBackend.Cldr)
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
  @spec number_symbols_for(LanguageTag.t() | Locale.locale_name(), System.system_name(), Cldr.backend()) ::
          {:ok, Map.t()} | {:error, {Cldr.NoNumberSymbols, String.t()}}

  def number_symbols_for(%LanguageTag{} = locale, number_system, backend) do
    with {:ok, system_name} <- Cldr.Number.System.system_name_from(number_system, locale, backend),
         {:ok, symbols} <- number_symbols_for(locale, backend) do
      symbols
      |> Map.get(system_name)
      |> symbols_return(locale, number_system)
    end
  end

  def number_symbols_for(locale_name, number_system, backend) when is_binary(locale_name) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      number_symbols_for(locale, number_system, backend)
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
