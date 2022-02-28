defmodule Cldr.Number.Symbol do
  @moduledoc """
  Functions to manage the symbol definitions for a locale and
  number system.

  """

  alias Cldr.Locale
  alias Cldr.LanguageTag
  alias Cldr.Number.System

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

  @type t :: %__MODULE__{
    decimal: String.t(),
    group: String.t(),
    exponential: String.t(),
    infinity: String.t(),
    list: String.t(),
    minus_sign: String.t(),
    nan: String.t(),
    per_mille: String.t(),
    percent_sign: String.t(),
    plus_sign: String.t(),
    superscripting_exponent: String.t(),
    time_separator: String.t()
  }

  @doc """
  Returns a map of `Cldr.Number.Symbol.t` structs of the number symbols for each
  of the number systems of a locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`.  The
    default is `Cldr.get_locale/1`.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

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
  @spec number_symbols_for(LanguageTag.t() | Locale.locale_name(), Cldr.backend()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def number_symbols_for(locale, backend) do
    Module.concat(backend, Number.Symbol).number_symbols_for(locale)
  end

  @doc """
  Returns the number symbols for a specific locale and number system.

  ## Options

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`.  The
    default is `Cldr.get_locale/1`.

  * `number_system` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

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
  @spec number_symbols_for(
          LanguageTag.t() | Locale.locale_name(),
          System.system_name(),
          Cldr.backend()
        ) :: {:ok, map()} | {:error, {Cldr.NoNumberSymbols, String.t()}}

  def number_symbols_for(%LanguageTag{} = locale, number_system, backend) do
    with {:ok, system_name} <-
           Cldr.Number.System.system_name_from(number_system, locale, backend),
         {:ok, symbols} <- number_symbols_for(locale, backend) do
      symbols
      |> Map.get(system_name)
      |> symbols_return(locale, number_system)
    end
  end

  def number_symbols_for(locale_name, number_system, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      number_symbols_for(locale, number_system, backend)
    end
  end

  @doc """
  Returns a list of all decimal symbols defined
  by the locales configured in the given backend as
  a list.

  ## Arguments

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  """
  def all_decimal_symbols(backend) do
    Module.concat(backend, Number.Symbol).all_decimal_symbols
  end

  @doc """
  Returns a list of all grouping symbols defined
  by the locales configured in the given backend as
  a list.

  ## Arguments

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  """
  def all_grouping_symbols(backend) do
    Module.concat(backend, Number.Symbol).all_grouping_symbols
  end

  @doc """
  Returns a list of all decimal symbols defined
  by the locales configured in the given backend as
  a string.

  This string can be used as a character class
  when builing a regular expression.

  ## Arguments

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  """
  def all_decimal_symbols_class(backend) do
    Module.concat(backend, Number.Symbol).all_decimal_symbols_class
  end

  @doc """
  Returns a list of all grouping symbols defined
  by the locales configured in the given backend as
  a string.

  This string can be used as a character class
  when builing a regular expression.

  ## Arguments

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  """
  def all_grouping_symbols_class(backend) do
    Module.concat(backend, Number.Symbol).all_grouping_symbols_class
  end

  @doc false
  def symbols_return(nil, locale, number_system) do
    {
      :error,
      {
        Cldr.NoNumberSymbols,
        "The locale #{inspect(locale)} does not have " <>
          "any symbols for number system #{inspect(number_system)}"
      }
    }
  end

  @doc false
  def symbols_return(symbols, _locale, _number_system) do
    {:ok, symbols}
  end
end
