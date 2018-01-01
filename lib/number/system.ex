defmodule Cldr.Number.System do
  @moduledoc """
  Functions to manage number systems which describe the numbering characteristics for a locale.

  A number system defines the digits (if they exist in this number system) or
  or rules (if the number system does not have decimal digits).

  The system name is also used as a key to define the separators that are used
  when formatting a number is this number_system. See
  `Cldr.Number.Symbol.number_symbols_for/2`.
  """

  require Cldr
  require Cldr.Rbnf.{Spellout, NumberSystem, Ordinal}

  alias Cldr.Locale
  alias Cldr.Number.Symbol
  alias Cldr.LanguageTag

  @default_number_system_type :default

  @type system_name :: atom()
  @type types :: :default | :native | :traditional | :finance

  defdelegate known_number_systems, to: Cldr
  defdelegate known_number_system_types, to: Cldr

  @doc """
  Return the default number system type name.

  Currently this is `:default`.  Note that this is
  not the number system itself but the type of the
  number system.  It can be used to find the
  default number system for a given locale with
  `number_systems_for(locale)[default_number_system()]`.

  ## Example

      iex> Cldr.Number.System.default_number_system_type
      :default

  """
  def default_number_system_type do
    @default_number_system_type
  end

  @doc """
  Return a map of all CLDR number systems and definitions.

  ## Example

      iex> Cldr.Number.System.number_systems |> Enum.count
      78

  """
  @spec number_systems :: Map.t()
  @number_systems Cldr.Config.number_systems()

  def number_systems do
    @number_systems
  end

  @systems_with_digits Enum.reject(@number_systems, fn {_name, system} ->
                         is_nil(system[:digits])
                       end)

  @doc """
  Number systems that have their own digit characters defined.
  """
  def systems_with_digits do
    @systems_with_digits
  end

  @doc """
  Returns the number systems available for a locale
  or `{:error, message}` if the locale is not known.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

  ## Examples

      iex> Cldr.Number.System.number_systems_for Cldr.Locale.new!("en")
      {:ok, %{default: :latn, native: :latn}}

      iex> Cldr.Number.System.number_systems_for Cldr.Locale.new!("th")
      {:ok, %{default: :latn, native: :thai}}

      iex> Cldr.Number.System.number_systems_for Cldr.Locale.new!("zz")
      {:error, {Cldr.UnknownLocaleError, "The locale \\"zz\\" is not known."}}

  """
  @spec number_systems_for(Locale.name() | LanguageTag.t()) :: Map.t()
  def number_systems_for(locale \\ Cldr.get_current_locale())

  for locale_name <- Cldr.Config.known_locale_names() do
    systems =
      locale_name
      |> Cldr.Config.get_locale()
      |> Map.get(:number_systems)

    def number_systems_for(unquote(locale_name)) do
      {:ok, unquote(Macro.escape(systems))}
    end

    def number_systems_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
      number_systems_for(unquote(locale_name))
    end
  end

  def number_systems_for(locale) do
    {:error, Locale.locale_error(locale)}
  end

  @doc """
  Returns the number systems available for a locale
  or raises if the locale is not known.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

  ## Examples

      iex> Cldr.Number.System.number_systems_for! Cldr.Locale.new!("en")
      %{default: :latn, native: :latn}

      iex> Cldr.Number.System.number_systems_for! Cldr.Locale.new!("th")
      %{default: :latn, native: :thai}

  """
  @spec number_systems_for!(Locale.name() | LanguageTag.t()) :: Map.t()
  def number_systems_for!(locale) do
    case number_systems_for(locale) do
      {:error, {exception, message}} ->
        raise exception, message

      {:ok, systems} ->
        systems
    end
  end

  @doc """
  Returns the actual number system from a number system type.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  This function will decode a number system type into the actual
  number system.  If the number system provided can't be decoded
  it is returned as is.

  ## Examples

      iex> Cldr.Number.System.number_system_for Cldr.Locale.new!("th"), :latn
      {:ok, %{digits: "0123456789", type: :numeric}}

      iex> Cldr.Number.System.number_system_for Cldr.Locale.new!("en"), :default
      {:ok, %{digits: "0123456789", type: :numeric}}

      iex> Cldr.Number.System.number_system_for Cldr.Locale.new!("he"), :traditional
      {:ok, %{rules: "hebrew", type: :algorithmic}}

      iex> Cldr.Number.System.number_system_for Cldr.Locale.new!("en"), :finance
      {
        :error,
        {Cldr.UnknownNumberSystemError,
          "The number system :finance is unknown for the locale named \\"en\\". Valid number systems are %{default: :latn, native: :latn}"}
      }

      iex> Cldr.Number.System.number_system_for Cldr.Locale.new!("en"), :native
      {:ok, %{digits: "0123456789", type: :numeric}}

  """
  @spec number_system_for(Locale.name() | LanguageTag.t(), System.name()) :: [atom(), ...]
  def number_system_for(locale, system_name) do
    with {:ok, locale} <- Cldr.validate_locale(locale),
         {:ok, system_name} <- system_name_from(system_name, locale) do
      {:ok, Map.get(number_systems(), system_name)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the names of the number systems available for
  a locale or an `{:error, message}` tuple if the locale
  is not known.

  * `locale` is any locale returned by `Cldr.Locale.new!/1` or
    a `Cldr.LanguageTag` struct

  ## Examples

      iex> Cldr.Number.System.number_system_names_for Cldr.Locale.new!("en")
      {:ok, [:latn]}

      iex> Cldr.Number.System.number_system_names_for Cldr.Locale.new!("th")
      {:ok, [:latn, :thai]}

      iex> Cldr.Number.System.number_system_names_for Cldr.Locale.new!("he")
      {:ok, [:latn, :hebr]}

      iex> Cldr.Number.System.number_system_names_for Cldr.Locale.new!("zz")
      {:error, {Cldr.UnknownLocaleError, "The locale \\"zz\\" is not known."}}

  """
  @spec number_system_names_for(Locale.name() | LanguageTag.t()) :: [atom(), ...]
  def number_system_names_for(locale \\ Cldr.default_locale()) do
    with {:ok, locale} <- Cldr.validate_locale(locale),
         {:ok, systems} <- number_systems_for(locale) do
      {:ok, systems |> Map.values() |> Enum.uniq()}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the names of the number systems available for
  a locale or an `{:error, message}` tuple if the locale
  is not known.

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

  ## Examples

      iex> Cldr.Number.System.number_system_names_for!("en")
      [:latn]

      iex> Cldr.Number.System.number_system_names_for!("th")
      [:latn, :thai]

      iex> Cldr.Number.System.number_system_names_for!("he")
      [:latn, :hebr]

  """
  @spec number_system_names_for!(Locale.name() | LanguageTag.t()) :: [system_name, ...]
  def number_system_names_for!(locale) do
    case number_system_names_for(locale) do
      {:error, {exception, message}} ->
        raise exception, message

      {:ok, names} ->
        names
    end
  end

  @doc """
  Returns a number system name for a given locale and number system reference.

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

  Number systems can be references in one of two ways:

  * As a number system type such as :default, :native, :traditional and
    :finance. This allows references to a number system for a locale in a
    consistent fashion for a given use

  * WIth the number system name directly, such as :latn, :arab or any of the
    other 70 or so

  This function dereferences the supplied `system_name` and returns the
  actual system name.

  ## Examples

      ex> Cldr.Number.System.system_name_from(:default, Cldr.Locale.new!( "en"))
      {:ok, :latn}

      iex> Cldr.Number.System.system_name_from("latn", Cldr.Locale.new!("en"))
      {:ok, :latn}

      iex> Cldr.Number.System.system_name_from(:native, Cldr.Locale.new!("en"))
      {:ok, :latn}

      iex> Cldr.Number.System.system_name_from(:nope, Cldr.Locale.new!("en"))
      {
        :error,
        {Cldr.UnknownNumberSystemError, "The number system :nope is unknown"}
      }

  Note that return value is not guaranteed to be a valid
  number system for the given locale as demonstrated in the third example.
  """
  @spec system_name_from(system_name, Locale.locale_name() | LanguageTag.t()) :: atom
  def system_name_from(system_name, locale \\ Cldr.get_current_locale()) do
    with {:ok, locale} <- Cldr.validate_locale(locale),
         {:ok, number_system} <- validate_number_system_or_type(system_name),
         {:ok, number_systems} <- number_systems_for(locale) do
      cond do
        Map.has_key?(number_systems, number_system) ->
          {:ok, Map.get(number_systems, number_system)}

        number_system in Map.values(number_systems) ->
          {:ok, number_system}

        true ->
          {:error, unknown_number_system_for_locale_error(system_name, locale, number_systems)}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns a number system name for a given locale and number system reference
  and raises if the number system is not available for the given locale.

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

  ## Examples

    iex> Cldr.Number.System.system_name_from!(:default, Cldr.Locale.new!( "en"))
    :latn

    iex> Cldr.Number.System.system_name_from!("latn", Cldr.Locale.new!("en"))
    :latn

    iex> Cldr.Number.System.system_name_from!(:traditional, Cldr.Locale.new!("he"))
    :hebr

  """
  def system_name_from!(system_name, locale \\ Cldr.get_current_locale()) do
    case system_name_from(system_name, locale) do
      {:error, {exception, message}} ->
        raise exception, message

      {:ok, name} ->
        name
    end
  end

  @doc """
  Returns locale and number systems that have the same digits and
  separators as the supplied one.

  Transliterating between locale & number systems is expensive.  To avoid
  unncessary transliteration we look for locale and number systems that have
  the same digits and separators.  Typically we are comparing to locale "en"
  and number system "latn" since this is what the number formatting routines use
  as placeholders.
  """
  @spec number_systems_like(LanguageTag.t() | Locale.locale_name(), system_name) ::
          {:ok, List.t()} | {:error, tuple}

  def number_systems_like(locale, number_system) do
    with {:ok, _} <- Cldr.validate_locale(locale),
         {:ok, %{digits: digits}} <- number_system_for(locale, number_system),
         {:ok, symbols} <- Symbol.number_symbols_for(locale, number_system),
         {:ok, names} <- number_system_names_for(locale) do
      likes = do_number_systems_like(digits, symbols, names)
      {:ok, likes}
    end
  end

  defp do_number_systems_like(digits, symbols, names) do
    Enum.map(Cldr.known_locale_names(), fn this_locale ->
      Enum.reduce(names, [], fn this_system, acc ->
        locale = Locale.new!(this_locale)

        case number_system_for(locale, this_system) do
          {:error, _} ->
            acc

          {:ok, %{digits: these_digits}} ->
            {:ok, these_symbols} = Symbol.number_symbols_for(locale, this_system)

            if digits == these_digits && symbols == these_symbols do
              acc ++ {locale, this_system}
            end
        end
      end)
    end)
    |> Enum.reject(&(is_nil(&1) || &1 == []))
  end

  @doc """
  Returns `{:ok, digits}` for a number system, or an `{:error, message}` if the
  number system is not known.

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  ## Examples

      iex> Cldr.Number.System.number_system_digits(:latn)
      {:ok, "0123456789"}

      iex> Cldr.Number.System.number_system_digits(:nope)
      {:error, {Cldr.UnknownNumberSystemError, "The number system :nope is not known or does not have digits"}}

  """
  def number_system_digits(system_name) do
    if system = systems_with_digits()[system_name] do
      {:ok, Map.get(system, :digits)}
    else
      {:error, number_system_digits_error(system_name)}
    end
  end

  @doc """
  Returns `digits` for a number system, or raises an exception if the
  number system is not know.

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  ## Examples

      iex> Cldr.Number.System.number_system_digits! :latn
      "0123456789"

      Cldr.Number.System.number_system_digits! :nope
      ** (Cldr.UnknownNumberSystemError) The number system :nope is not known or does not have digits

  """
  def number_system_digits!(system_name) do
    case number_system_digits(system_name) do
      {:ok, digits} ->
        digits

      {:error, {exception, message}} ->
        raise exception, message
    end
  end

  @doc """
  Converts a number into the representation of
  a non-latin number system.

  This function converts numbers to a known
  number system only, it does not provide number
  formatting.

  * `number` is a `float`, `integer` or `Decimal`

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  There are two types of number systems in CLDR:

  * `:numeric` in which the number system defines
    a direct mapping between the latin digits `0..9`
    into a the number system equivalent.  In this case,
  ` to_system/2` invokes `Cldr.Number.Transliterate.transliterate_digits/3`
    for the given number.

  * `:algorithmic` in which the number system
    does not have the same structure as the `:latn`
    number system and therefore the conversion is
    done algorithmically.  For CLDR the algorithm
    is implemented through `Cldr.Rbnf` rulesets.
    These rulesets are considered by CLDR to be
    less rigorous than the `:numeric` number systems
    and caution and testing for a specific use case
    is recommended.

  ## Examples

      iex> Cldr.Number.System.to_system 123456, :hebr
      {:ok, "ק׳׳ת׳"}

      iex> Cldr.Number.System.to_system 123, :hans
      {:ok, "一百二十三"}

      iex> Cldr.Number.System.to_system 123, :hant
      {:ok, "一百二十三"}

      iex> Cldr.Number.System.to_system 123, :hansfin
      {:ok, "壹佰贰拾叁"}

  """
  @spec to_system(Math.number_or_decimal(), atom) :: String.t()
  def to_system(number, system_name)

  for {system, definition} <- @number_systems do
    if definition.type == :numeric do
      def to_system(number, unquote(system)) do
        string =
          number
          |> to_string
          |> Cldr.Number.Transliterate.transliterate_digits(:latn, unquote(system))

        {:ok, string}
      end
    else
      {module, function, locale_name} = Cldr.Config.rbnf_rule_function(definition.rules)

      if function_exported?(module, function, 2) do
        locale = Locale.new!(locale_name)

        def to_system(number, unquote(system)) do
          with {:ok, _locale} <- Cldr.validate_locale(unquote(Macro.escape(locale))) do
            {:ok, unquote(module).unquote(function)(number, unquote(Macro.escape(locale)))}
          else
            {:error, reason} -> {:error, reason}
          end
        end
      end
    end
  end

  def to_system(_number, system) do
    {:error, Cldr.unknown_number_system_error(system)}
  end

  @doc """
  Converts a number into the representation of
  a non-latin number system. Returns a converted
  string or raises on error.

  * `number` is a `float`, `integer` or `Decimal`

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  See `Cldr.Number.System.to_string/2` for further
  information.

  ## Examples

      iex> Cldr.Number.System.to_system! 123, :hans
      "一百二十三"

      iex> Cldr.Number.System.to_system! 123, :hant
      "一百二十三"

      iex> Cldr.Number.System.to_system! 123, :hansfin
      "壹佰贰拾叁"

  """
  def to_system!(number, system_name) do
    case to_system(number, system_name) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Generate a transliteration map between two character classes
  """
  def generate_transliteration_map(from, to) when is_binary(from) and is_binary(to) do
    do_generate_transliteration_map(from, to, String.length(from), String.length(to))
  end

  defp do_generate_transliteration_map(from, to, from_length, to_length)
       when from_length == to_length do
    from
    |> String.graphemes()
    |> Enum.zip(String.graphemes(to))
    |> Enum.into(%{})
  end

  defp do_generate_transliteration_map(from, to, _from_length, _to_length) do
    {:error, {ArgumentError, "#{inspect(from)} and #{inspect(to)} aren't the same length"}}
  end

  defp validate_number_system_or_type(number_system) do
    with {:ok, number_system} <- Cldr.validate_number_system(number_system) do
      {:ok, number_system}
    else
      {:error, _} ->
        with {:ok, number_system} <- Cldr.validate_number_system_type(number_system) do
          {:ok, number_system}
        else
          {:error, _reason} -> {:error, Cldr.unknown_number_system_error(number_system)}
        end
    end
  end

  @doc """
  Returns an error tuple for an number system unknown to a given locale.

    * `number_system` is any number system name **not** returned by `Cldr.known_number_systems/0`

    * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
      or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`

    * `valid_number_systems` is a map returned by `Cldr.Number.System.number_systems_for/1`

  ## Examples


  """
  def unknown_number_system_for_locale_error(number_system, locale, valid_number_systems)
      when is_atom(number_system) do
    {
      Cldr.UnknownNumberSystemError,
      "The number system #{inspect(number_system)} is unknown " <>
        "for the locale named #{Cldr.locale_name(locale)}. " <>
        "Valid number systems are #{inspect(valid_number_systems)}"
    }
  end

  defp number_system_digits_error(system_name) do
    {
      Cldr.UnknownNumberSystemError,
      "The number system #{inspect(system_name)} is not known or does not have digits"
    }
  end
end
