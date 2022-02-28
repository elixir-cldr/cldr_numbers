defmodule Cldr.Number.Transliterate do
  @moduledoc """
  Transliteration for digits and separators.

  Transliterating a string is an expensive business.  First the string has to
  be exploded into its component graphemes.  Then for each grapheme we have
  to map to the equivalent in the other `{locale, number_system}`.  Then we
  have to reassemble the string.

  Effort is made to short circuit where possible. Transliteration is not
  required for any `{locale, number_system}` that is the same as `{"en",
  "latn"}` since the implementation uses this combination for the placeholders during
  formatting already. When short circuiting is possible (typically the en-*
  locales with "latn" number_system - the total number of short circuited
  locales is 211 of the 537 in CLDR) the overall number formatting is twice as
  fast than when formal transliteration is required.

  ### Configuring precompilation of digit transliterations

  This module includes `Cldr.Number.Transliterate.transliterate_digits/3` which transliterates
  digits between number systems.  For example from :arabic to :latn.  Since generating a
  transliteration map is slow, pairs of transliterations can be configured so that the
  transliteration map is created at compile time and therefore speeding up transliteration at
  run time.

  To configure these transliteration pairs, add the following to your backend configuration:

      defmodule MyApp.Cldr do
        use Cldr,
        locale: ["en", "fr", "th"],
        default_locale: "en",
        precompile_transliterations: [{:latn, :thai}, {:arab, :thai}]
      end

  Where each tuple in the list configures one transliteration map.  In this example, two maps are
  configured: from :latn to :thai and from :arab to :thai.

  A list of configurable number systems is returned by `Cldr.Number.System.systems_with_digits/0`.

  If a transliteration is requested between two number pairs that have not been configured for
  precompilation, a warning is logged.

  """

  require Logger
  alias Cldr.Number.System

  @doc """
  Transliterates from latin digits to another number system's digits.

  Transliterates the latin digits 0..9 to their equivalents in
  another number system. Also transliterates the decimal and grouping
  separators as well as the plus, minus and exponent symbols. Any other character
  in the string will be returned "as is".

  * `sequence` is the string to be transliterated.

  * `locale` is any known locale, defaulting to `Cldr.get_locale/0`.

  * `number_system` is any known number system. If expressed as a `string` it
    is the actual name of a known number system. If epressed as an `atom` it is
    used as a key to look up a number system for the locale (the usual keys are
    `:default` and `:native` but :traditional and :finance are also part of the
    standard). See `Cldr.Number.System.number_systems_for/2` for a locale to
    see what number system types are defined. The default is `:default`.

  For available number systems see `Cldr.Number.System.number_systems/0`
  and `Cldr.Number.System.number_systems_for/2`.  Also see
  `Cldr.Number.Symbol.number_symbols_for/2`.


  ## Examples

      iex> Cldr.Number.Transliterate.transliterate("123556", "en", :default, TestBackend.Cldr)
      "123556"

      iex> Cldr.Number.Transliterate.transliterate("123,556.000", "fr", :default, TestBackend.Cldr)
      "123 556,000"

      iex> Cldr.Number.Transliterate.transliterate("123556", "th", :default, TestBackend.Cldr)
      "123556"

      iex> Cldr.Number.Transliterate.transliterate("123556", "th", "thai", TestBackend.Cldr)
      "๑๒๓๕๕๖"

      iex> Cldr.Number.Transliterate.transliterate("123556", "th", :native, TestBackend.Cldr)
      "๑๒๓๕๕๖"

      iex> Cldr.Number.Transliterate.transliterate("Some number is: 123556", "th", "thai", TestBackend.Cldr)
      "Some number is: ๑๒๓๕๕๖"

  """
  def transliterate(sequence, locale, number_system, backend) do
    Module.concat(backend, Number.Transliterate).transliterate(sequence, locale, number_system)
  end

  def transliterate_digits(digits, from_system, from_system) do
    digits
  end

  def transliterate_digits(digits, from_system, to_system) when is_binary(digits) do
    with {:ok, from} <- System.number_system_digits(from_system),
         {:ok, to} <- System.number_system_digits(to_system) do
      log_warning(
        "Transliteration from number system #{inspect(from_system)} to " <>
          "#{inspect(to_system)} requires dynamic generation of a transliteration map for " <>
          "each function call which is slow. Please consider configuring this transliteration pair. " <>
          "See `Cldr.Number.Transliteration` for further information."
      )

      map = System.generate_transliteration_map(from, to)
      do_transliterate_digits(digits, map)
    else
      {:error, message} -> {:error, message}
    end
  end

  if macro_exported?(Logger, :warning, 2) do
    defp log_warning(message) do
      Logger.warning(fn -> message end)
    end
  else
    defp log_warning(message) do
      Logger.warn(message)
    end
  end

  defp do_transliterate_digits(digits, map) do
    digits
    |> String.graphemes()
    |> Enum.map(&Map.get(map, &1, &1))
    |> Enum.join()
  end
end
