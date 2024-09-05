defmodule Cldr.Number.System do
  @moduledoc """
  Number systems information is used to define different representations
  for numeric values to an end user. Numbering systems are defined in CLDR
  as one of two different types: algorithmic and numeric.

  Numeric systems are simply a decimal based system that uses a
  predefined set of digits to represent numbers. Examples are
  Western digits (ASCII digits), Thai digits, Devanagari digits.

  Algorithmic systems are more complex in nature, since the proper
  formatting and presentation of a numeric quantity is based on some
  algorithm or set of rules. Examples are Chinese numerals, Hebrew numerals,
  or Roman numerals.

  In CLDR, the rules for presentation of numbers in an algorithmic system
  are defined using the rules based number formats (RBNF) which are
  implemented in `Cldr.Number.Rbnf`.

  ### Number system attributes

  Attributes for a number system map are as follows:

  * `:id` specifies the name of the number system that can be used to designate
    its use in formatting.
  * `:type` specifies whether the number system is algorithmic or numeric.
  * `:digits`For numeric systems, specifies the digits used to represent numbers,
    in order, starting from zero.
  * `:rules` specifies the RBNF ruleset to be used for formatting numbers from this
    number system. The rules specifier can contain simply a ruleset name, in
    which case the ruleset is assumed to be found in the rule set grouping
    "NumberingSystemRules". Alternatively, the specifier can denote a specific
    locale, ruleset grouping, and ruleset name, separated by slashes.

  An example of a number system map is:

      iex> Cldr.Number.System.number_systems()[:latn]
      %{type: :numeric, digits: "0123456789"}

      iex> Cldr.Number.System.number_systems()[:taml]
      %{type: :algorithmic, rules: "tamil"}

  ### Number system types

  Each number system also categories number systems into various types:

  * `:native` defines the number system used for the native digits,
     usually defined as a part of the script used to write the language.
    `:native` number system can only be a numeric positional decimal-digit
     number system, using digits with General_Category=Decimal_Number. Note
     that In locales where the native number system is the default, it is
     assumed that the number system "latn" (Western digits 0-9) is always
     acceptable, and can be selected using the `-nu` keyword as part of a Unicode
     locale name.

  * `:traditional` defines the traditional numerals for a locale. This numbering
    system may be numeric or algorithmic. If the traditional number system is
    not defined, the native number system is used as a fallback.

  * `:finance` defines the number system used for financial quantities. This
    number system may be numeric or algorithmic. This is often used for
    ideographic languages such as Chinese, where it would be easy to alter an amount
    represented in the default number system simply by adding additional strokes.
    If the financial number system is not specified, the
    default number system is used as a fallback.

  An example of a number system map for the `:zh` locale is:

      iex> Cldr.Number.System.number_systems_for(:zh, MyApp.Cldr)
      {:ok,
       %{default: :latn, native: :hanidec, traditional: :hans, finance: :hansfin}}

  This indicates that for the locale `:zh`, the number systems `:latn`, `:hanidec`,
  `:hans` and `:hansfin` are supported. These number systems are a mix of
  nuemeric systems and algorithmic systems.

  ### Specifying the number system in a locale name

  The types defined for other number systems can be used in a Unicode locale
  identifier to select the proper number system without having to know the
  specific number system by name. For example:

  * To select the Hindi language using the native digits for numeric formatting, use
    locale ID: "hi-IN-u-nu-native".

  * To select the Chinese language using the appropriate financial numerals, use
    locale ID: "zh-u-nu-finance".

  * To select the Tamil language using the traditional Tamil numerals, use
    locale ID: "ta-u-nu-traditio".

  * To select the Arabic language using western digits 0-9, use locale ID:
    "ar-u-nu-latn".

  """

  alias Cldr.Locale
  alias Cldr.Number.{System, Symbol}
  alias Cldr.LanguageTag
  alias Cldr.Math

  @default_number_system_type :default

  @type system_name :: atom()
  @type types :: :default | :native | :traditional | :finance

  defdelegate known_number_systems, to: Cldr
  defdelegate known_number_system_types(backend), to: Cldr

  @deprecated "Use numeric_systems/0 instead"
  defdelegate systems_with_digits, to: __MODULE__, as: :numeric_systems

  @doc """
  Return the default number system type name.

  The default number system type is `#{inspect(@default_number_system_type)}`.
  Note that this is not the number system itself but the type of the
  number system.

  ## Example

      iex> Cldr.Number.System.default_number_system_type()
      :default

  """
  def default_number_system_type do
    @default_number_system_type
  end

  @doc """
  Return a map of all CLDR number systems and their
  definitions.

  ## Example

      iex> Cldr.Number.System.number_systems() |> Enum.count
      96

  """
  @spec number_systems :: unquote(Cldr.Type.number_systems())
  @number_systems Cldr.Config.number_systems()

  def number_systems do
    @number_systems
  end

  @numeric_systems Enum.reject(@number_systems, fn {_name, system} ->
                     is_nil(system[:digits])
                   end)
                   |> Map.new()

  @doc """
  Returns a map of the number systems that have
  their own digit character representations.

  See also `Cldr.Number.System.algorithmic_systems/0`.

  ### Example

      ==> Cldr.Number.System.numeric_systems()
      %{
        gonm: %{type: :numeric, digits: "𑵐𑵑𑵒𑵓𑵔𑵕𑵖𑵗𑵘𑵙"},
        mathdbl: %{type: :numeric, digits: "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡"},
        bhks: %{type: :numeric, digits: "𑱐𑱑𑱒𑱓𑱔𑱕𑱖𑱗𑱘𑱙"},
        deva: %{type: :numeric, digits: "०१२३४५६७८९"},
        adlm: %{type: :numeric, digits: "𞥐𞥑𞥒𞥓𞥔𞥕𞥖𞥗𞥘𞥙"},
        telu: %{type: :numeric, digits: "౦౧౨౩౪౫౬౭౮౯"},
        cakm: %{type: :numeric, digits: "𑄶𑄷𑄸𑄹𑄺𑄻𑄼𑄽𑄾𑄿"},
        mathsans: %{
          type: :numeric,
          digits: "𝟢𝟣𝟤𝟥𝟦𝟧𝟨𝟩𝟪𝟫"
        },
        nkoo: %{type: :numeric, digits: "߀߁߂߃߄߅߆߇߈߉"},
        ...
      }

  """

  def numeric_systems do
    @numeric_systems
  end

  @algorithmic_systems Enum.filter(@number_systems, fn {_name, system} ->
                         system.type == :algorithmic
                       end)
                       |> Map.new()

  @doc """
  Returns a map of the number systems that are
  algorithmic.

  Algorithmic number systems don't have decimal
  digits. Numbers are formed by algorithm using
  rules based number formats.

  The `:rules` field contains the name of the
  RBNF rule that will be used with formatting
  a number with `format: :standard` (which is
  also the default when no `:format` is specified).

  See also `Cldr.Number.System.numeric_systems/0`.

  ### Example

      ==> Cldr.Number.System.algorithmic_systems()
      %{
        roman: %{type: :algorithmic, rules: "roman-upper"},
        armn: %{type: :algorithmic, rules: "armenian-upper"},
        armnlow: %{type: :algorithmic, rules: "armenian-lower"},
        cyrl: %{type: :algorithmic, rules: "cyrillic-lower"},
        ethi: %{type: :algorithmic, rules: "ethiopic"},
        geor: %{type: :algorithmic, rules: "georgian"},
        grek: %{type: :algorithmic, rules: "greek-upper"},
        greklow: %{type: :algorithmic, rules: "greek-lower"},
        hanidays: %{
          type: :algorithmic,
          rules: "zh/SpelloutRules/spellout-numbering-days"
        },
        hans: %{type: :algorithmic, rules: "zh/SpelloutRules/spellout-cardinal"},
        hansfin: %{
          type: :algorithmic,
          rules: "zh/SpelloutRules/spellout-cardinal-financial"
        },
        ...
      }

  """
  @doc since: "2.32.0"
  def algorithmic_systems do
    @algorithmic_systems
  end

  @doc """
  Returns the default RBNF rule name for an
  algorithmic number system.

  ### Arguments

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`.

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  ### Returns

  * `{:ok, {module, rule_function, locale}}` or

  * `{:error, {module(), reason}}`

  ### Example

      iex> Cldr.Number.System.default_rbnf_rule(:taml, MyApp.Cldr)
      {:ok, {MyApp.Cldr.Rbnf.NumberSystem, :tamil, :und}}

      iex> Cldr.Number.System.default_rbnf_rule(:hebr, MyApp.Cldr)
      {:ok, {MyApp.Cldr.Rbnf.NumberSystem, :hebrew, :und}}

      iex> Cldr.Number.System.default_rbnf_rule(:jpanfin, MyApp.Cldr)
      {:ok, {MyApp.Cldr.Rbnf.Spellout, :spellout_cardinal_financial, :ja}}

      iex> Cldr.Number.System.default_rbnf_rule(:latn, MyApp.Cldr)
      {:error,
       {Cldr.UnknownNumberSystemError, "The number system :latn is not algorithmic"}}

  """
  def default_rbnf_rule(system_name, backend) do
    case Map.fetch(algorithmic_systems(), system_name) do
      {:ok, definition} ->
        {:ok, Cldr.Config.rbnf_rule_function(definition.rules, backend)}

      :error ->
        {:error, algorithmic_system_error(system_name)}
    end
  end

  @doc """
  Returns the default number system from a language tag
  or locale name.

  ### Arguments

  * `locale` is any language tag returned be `Cldr.Locale.new/2`
    or a locale name in the list returned by `Cldr.known_locale_names/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ### Returns

  * A number system name as an atom.

  ### Examples

      iex> Cldr.Number.System.number_system_from_locale("en-US-u-nu-thai", MyApp.Cldr)
      :thai

      iex> Cldr.Number.System.number_system_from_locale(:"en-US", MyApp.Cldr)
      :latn

  """
  @spec number_system_from_locale(Locale.locale_reference(), Cldr.backend()) ::
          system_name | {:error, {module(), String.t()}}

  def number_system_from_locale(%LanguageTag{locale: %{numbers: nil}} = locale, backend) do
    locale
    |> number_systems_for!(backend)
    |> Map.fetch!(default_number_system_type())
  end

  def number_system_from_locale(%LanguageTag{locale: %{numbers: number_system}}, _backend) do
    number_system
  end

  def number_system_from_locale(%LanguageTag{} = locale, backend) do
    locale
    |> number_systems_for!(backend)
    |> Map.fetch!(default_number_system_type())
  end

  def number_system_from_locale(locale_name, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      number_system_from_locale(locale, backend)
    end
  end

  @doc """
  Returns the number system from a language tag
  or locale name.

  ### Arguments

  * `locale` is any language tag returned be `Cldr.Locale.new/2`

  ### Returns

  * A number system name as an atom.

  ### Examples

      iex> {:ok, locale} = MyApp.Cldr.validate_locale("en-US-u-nu-thai")
      iex> Cldr.Number.System.number_system_from_locale(locale)
      :thai

      iex> {:ok, locale} = MyApp.Cldr.validate_locale("en-US")
      iex> Cldr.Number.System.number_system_from_locale(locale)
      :latn

      iex> Cldr.Number.System.number_system_from_locale("ar-EG")
      :arab

  """
  @spec number_system_from_locale(Locale.locale_reference()) ::
          system_name | {:error, {module(), String.t()}}

  def number_system_from_locale(%LanguageTag{locale: %{numbers: nil}} = locale) do
    number_system_from_locale(locale.cldr_locale_name, locale.backend)
  end

  def number_system_from_locale(%LanguageTag{locale: %{numbers: number_system}}) do
    number_system
  end

  def number_system_from_locale(%LanguageTag{cldr_locale_name: locale, backend: backend}) do
    number_system_from_locale(locale, backend)
  end

  def number_system_from_locale(locale) do
    {locale, backend} = Cldr.locale_and_backend_from(locale, nil)
    number_system_from_locale(locale, backend)
  end

  @doc """
  Returns the number system types mapped to a number
  system name for a locale.

  When formatting a nummber it is acceptable to refer
  to either the nuumber system type or the number system
  name.

  ### Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``.

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  ### Returns

  * `{:ok, number_system_map}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.Number.System.number_systems_for(:en)
      {:ok, %{default: :latn, native: :latn}}

      iex> Cldr.Number.System.number_systems_for(:th)
      {:ok, %{default: :latn, native: :thai}}

      iex> Cldr.Number.System.number_systems_for("zz", TestBackend.Cldr)
      {:error, {Cldr.InvalidLanguageError, "The language \\"zz\\" is invalid"}}

  """
  @spec number_systems_for(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def number_systems_for(locale, backend) do
    Module.concat(backend, Number.System).number_systems_for(locale)
  end

  @doc false
  def number_systems_for(locale) do
    number_systems_for(locale, Cldr.default_backend!())
  end

  @doc """
  Returns the number system types mapped to a number
  system name for a locale or raises an exception.

  ### Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`. The default is `Cldr.default_backend!/0`.

  ### Returns

  * `number_system_map` or

  * raises an exception.

  ### Examples

      iex> Cldr.Number.System.number_systems_for!("en")
      %{default: :latn, native: :latn}

      iex> Cldr.Number.System.number_systems_for!("th", TestBackend.Cldr)
      %{default: :latn, native: :thai}

  """
  @spec number_systems_for!(Locale.locale_reference(), Cldr.backend()) :: map() | no_return()

  def number_systems_for!(locale, backend) do
    case number_systems_for(locale, backend) do
      {:error, {exception, message}} ->
        raise exception, message

      {:ok, systems} ->
        systems
    end
  end

  @doc false
  def number_systems_for!(locale) do
    number_systems_for!(locale, Cldr.default_backend!())
  end

  @doc """
  Returns the actual number system from a number system type.

  ### Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ### Returns

  * `{:ok, number_system_map}` or

  * `{:error, {exception, reason}}`.

  ### Notes

  This function will decode a number system type into the actual
  number system.  If the number system provided can't be decoded
  it is returned as is.

  ### Examples

      iex> Cldr.Number.System.number_system_for("th", :latn, TestBackend.Cldr)
      {:ok, %{digits: "0123456789", type: :numeric}}

      iex> Cldr.Number.System.number_system_for("en", :default, TestBackend.Cldr)
      {:ok, %{digits: "0123456789", type: :numeric}}

      iex> Cldr.Number.System.number_system_for("he", :traditional, TestBackend.Cldr)
      {:ok, %{rules: "hebrew", type: :algorithmic}}

      iex> Cldr.Number.System.number_system_for("en", :finance, TestBackend.Cldr)
      {
        :error,
        {
          Cldr.UnknownNumberSystemError,
          "The number system :finance is unknown for the locale named :en. Valid number systems are %{default: :latn, native: :latn}"
        }
      }

      iex> Cldr.Number.System.number_system_for("en", :native, TestBackend.Cldr)
      {:ok, %{digits: "0123456789", type: :numeric}}

  """
  @spec number_system_for(Locale.locale_reference(), System.system_name(), Cldr.backend()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def number_system_for(locale, system_name, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, system_name} <- system_name_from(system_name, locale, backend) do
      {:ok, Map.get(number_systems(), system_name)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the names of the number systems available for
  a locale.

  ### Arguments

  * `locale` is any locale returned by `Cldr.Locale.new!/2`.

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  ### Returns

  * `{:ok, list_of_number_system_names}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.Number.System.number_system_names_for("en", TestBackend.Cldr)
      {:ok, [:latn]}

      iex> Cldr.Number.System.number_system_names_for("th", TestBackend.Cldr)
      {:ok, [:latn, :thai]}

      iex> Cldr.Number.System.number_system_names_for("he", TestBackend.Cldr)
      {:ok, [:latn, :hebr]}

      iex> Cldr.Number.System.number_system_names_for("zz", TestBackend.Cldr)
      {:error, {Cldr.InvalidLanguageError, "The language \\"zz\\" is invalid"}}

  """
  @spec number_system_names_for(Locale.locale_reference(), Cldr.backend()) ::
          {:ok, list(atom())} | {:error, {module(), String.t()}}

  def number_system_names_for(locale, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, systems} <- number_systems_for(locale, backend) do
      {:ok, systems |> Map.values() |> Enum.uniq()}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns the names of the number systems available for
  a locale or raises an exception.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  ### Returns

  * `list_of_number_system_names` or

  * raises and exception.

  ## Examples

      iex> Cldr.Number.System.number_system_names_for!("en", TestBackend.Cldr)
      [:latn]

      iex> Cldr.Number.System.number_system_names_for!("th", TestBackend.Cldr)
      [:latn, :thai]

      iex> Cldr.Number.System.number_system_names_for!("he", TestBackend.Cldr)
      [:latn, :hebr]

  """
  @spec number_system_names_for!(Locale.locale_reference(), Cldr.backend()) ::
          [system_name()] | no_return()

  def number_system_names_for!(locale, backend) do
    case number_system_names_for(locale, backend) do
      {:error, {exception, message}} ->
        raise exception, message

      {:ok, names} ->
        names
    end
  end

  @doc """
  Returns a number system name for a given locale and number
  system reference.

  ### Arguments

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  ### Returns

  * `{:ok, number_system_name}` or

  * `{:error, {exception, reason}}`.

  ### Notes

  Number systems can be references in one of two ways:

  * As a number system type such as :default, :native, :traditional and
    :finance. This allows references to a number system for a locale in a
    consistent fashion for a given use

  * WIth the number system name directly, such as :latn, :arab or any of the
    other 70 or so

  This function dereferences the supplied `system_name` and returns the
  actual system name.

  ### Examples

      ex> Cldr.Number.System.system_name_from(:default, "en", TestBackend.Cldr)
      {:ok, :latn}

      iex> Cldr.Number.System.system_name_from("latn", "en", TestBackend.Cldr)
      {:ok, :latn}

      iex> Cldr.Number.System.system_name_from(:native, "en", TestBackend.Cldr)
      {:ok, :latn}

      iex> Cldr.Number.System.system_name_from(:nope, "en", TestBackend.Cldr)
      {
        :error,
        {Cldr.UnknownNumberSystemError, "The number system :nope is unknown"}
      }

  Note that return value is not guaranteed to be a valid
  number system for the given locale as demonstrated in the third example.

  """
  @spec system_name_from(system_name, Locale.locale_reference(), Cldr.backend()) ::
          {:ok, atom()} | {:error, {module(), String.t()}}

  def system_name_from(system_name, locale, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, number_system} <- validate_number_system_or_type(system_name, backend),
         {:ok, number_systems} <- number_systems_for(locale, backend) do
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
  Returns a number system name for a given locale and number system
  reference or raises an exception.

  ### Arguments

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`.

  ### Returns

  * `number_system_name` or

  * raises an exception.

  ### Examples

      iex> Cldr.Number.System.system_name_from!(:default, "en", TestBackend.Cldr)
      :latn

      iex> Cldr.Number.System.system_name_from!("latn", "en", TestBackend.Cldr)
      :latn

      iex> Cldr.Number.System.system_name_from!(:traditional, "he", TestBackend.Cldr)
      :hebr

  """
  @spec system_name_from!(system_name, Locale.locale_reference(), Cldr.backend()) ::
          atom() | no_return()

  def system_name_from!(system_name, locale, backend) do
    case system_name_from(system_name, locale, backend) do
      {:error, {exception, message}} ->
        raise exception, message

      {:ok, name} ->
        name
    end
  end

  @doc """
  Returns locale and number systems that have the same digits and
  separators as the supplied one.

  ### Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ### Returns

  ### Notes

  * Transliterating between locale & number systems is expensive.  To avoid
    unnecessary transliteration we look for locale and number systems that have
    the same digits and separators.  Typically we are comparing to locale "en"
    and number system "latn" since this is what the number formatting routines use
    as placeholders.

  ### Examples

      ==> import Cldr.LanguageTag.Sigil
      ==> Cldr.Number.System.number_systems_like(:en, :latn, MyApp.Cldr)
      {:ok,
        [
          {~l[en], :latn},
          {~l[en-IN], :latn},
          {~l[ta], :latn},
          {~l[th], :latn},
          {~l[zh], :latn}
        ]
      }


  """
  @spec number_systems_like(Locale.locale_reference(), system_name, Cldr.backend()) ::
          {:ok, list()} | {:error, {module(), String.t()}}

  def number_systems_like(locale, number_system, backend) do
    with {:ok, _} <- Cldr.validate_locale(locale, backend),
         {:ok, %{digits: digits}} <- number_system_for(locale, number_system, backend),
         {:ok, symbols} <- Symbol.number_symbols_for(locale, number_system, backend),
         {:ok, names} <- number_system_names_for(locale, backend) do
      likes = do_number_systems_like(digits, symbols, names, backend)
      {:ok, likes}
    end
  end

  defp do_number_systems_like(digits, symbols, names, backend) do
    Enum.map(Cldr.known_locale_names(backend), fn this_locale ->
      Enum.reduce(names, [], fn this_system, acc ->
        locale = Locale.new!(this_locale, backend)

        case number_system_for(locale, this_system, backend) do
          {:error, _} ->
            acc

          {:ok, %{digits: these_digits}} ->
            {:ok, these_symbols} = Symbol.number_symbols_for(locale, this_system, backend)

            if digits == these_digits && symbols == these_symbols do
              acc ++ {locale, this_system}
            end
        end
      end)
    end)
    |> Enum.reject(&(is_nil(&1) || &1 == []))
  end

  @doc """
  Returns the digits for a number system as a
  string.

  ### Arguments

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  ### Returns

  * `{:ok, string_of_digits}` or

  * `{:error, {exception, reason}}`.

  ### Examples

      iex> Cldr.Number.System.number_system_digits(:latn)
      {:ok, "0123456789"}

      iex> Cldr.Number.System.number_system_digits(:nope)
      {:error, {Cldr.UnknownNumberSystemError, "The number system :nope is not known"}}

  """
  @spec number_system_digits(system_name()) ::
          {:ok, String.t()} | {:error, {module(), String.t()}}

  def number_system_digits(system_name) do
    if system = Map.get(numeric_systems(), system_name) do
      {:ok, Map.get(system, :digits)}
    else
      {:error, number_system_digits_error(system_name)}
    end
  end

  @doc """
  Returns `digits` for a number system, or raises an exception.

  ### Arguments

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  ### Returns

  * A string of the number systems digits or

  * raises an exception

  ### Examples

      iex> Cldr.Number.System.number_system_digits! :latn
      "0123456789"

      Cldr.Number.System.number_system_digits! :nope
      ** (Cldr.UnknownNumberSystemError) The number system :nope is not known or does not have digits

  """
  @spec number_system_digits!(system_name) :: String.t() | no_return()

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

  ### Arguments

  * `number` is a `float`, `integer` or `Decimal`

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ### Returns

  * `{:ok, string_of_digits}` or

  * `{:error, {exception, reason}}`

  ### Notes

  There are two types of number systems in CLDR:

  * `:numeric` in which the number system defines
    a direct mapping between the latin digits `0..9`
    into a the number system equivalent.  In this case,
  ` to_system/3` invokes `Cldr.Number.Transliterate.transliterate_digits/3`
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

  ### Examples

      iex> Cldr.Number.System.to_system(123456, :hebr, TestBackend.Cldr)
      {:ok, "קכ״ג׳תנ״ו"}

      iex> Cldr.Number.System.to_system(123, :hans, TestBackend.Cldr)
      {:ok, "一百二十三"}

      iex> Cldr.Number.System.to_system(123, :hant, TestBackend.Cldr)
      {:ok, "一百二十三"}

      iex> Cldr.Number.System.to_system(123, :hansfin, TestBackend.Cldr)
      {:ok, "壹佰贰拾叁"}

  """
  @spec to_system(Math.number_or_decimal(), atom, Cldr.backend()) ::
          {:ok, binary()} | {:error, {module(), String.t()}}

  def to_system(number, system_name, backend) do
    Module.concat(backend, Number.System).to_system(number, system_name)
  end

  @doc """
  Converts a number into the representation of
  a non-latin number system or raises an exception.

  ### Arguments

  * `number` is a `float`, `integer` or `Decimal`

  * `system_name` is any number system name returned by
    `Cldr.known_number_systems/0` or a number system type
    returned by `Cldr.known_number_system_types/0`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ### Returns

  * `string_of_digits` or

  * raises an exception

  See `Cldr.Number.System.to_system/3` for further
  information.

  ### Examples

      iex> Cldr.Number.System.to_system!(123, :hans, TestBackend.Cldr)
      "一百二十三"

      iex> Cldr.Number.System.to_system!(123, :hant, TestBackend.Cldr)
      "一百二十三"

      iex> Cldr.Number.System.to_system!(123, :hansfin, TestBackend.Cldr)
      "壹佰贰拾叁"

  """
  @spec to_system!(Math.number_or_decimal(), atom, Cldr.backend()) ::
          binary() | no_return()

  def to_system!(number, system_name, backend) do
    case to_system(number, system_name, backend) do
      {:ok, string} -> string
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Generate a transliteration map between two character classes.

  ### Arguments

  * `from` is any `String.t()` intended to represent the
    digits of a number system but that's not a requirement.

  * `to` is any `String.t()` that is the same length as `from`
    intended to represent the digits of a number system.

  ### Returns

  * A map where the keys are the graphemes in `from` and the
    values are the graphemes in `to` or

  * `{:error, {exception, reason}}`

  ### Examples

      iex> Cldr.Number.System.generate_transliteration_map("0123456789", "9876543210")
      %{
        "0" => "9",
        "1" => "8",
        "2" => "7",
        "3" => "6",
        "4" => "5",
        "5" => "4",
        "6" => "3",
        "7" => "2",
        "8" => "1",
        "9" => "0"
      }

      iex> Cldr.Number.System.generate_transliteration_map("0123456789", "987654321")
      {:error,
       {ArgumentError, "\\"0123456789\\" and \\"987654321\\" aren't the same length"}}

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

  defp validate_number_system_or_type(number_system, backend) do
    with {:ok, number_system} <- Cldr.validate_number_system(number_system) do
      {:ok, number_system}
    else
      {:error, _} ->
        with {:ok, number_system} <- Cldr.validate_number_system_type(number_system, backend) do
          {:ok, number_system}
        else
          {:error, _reason} -> {:error, Cldr.unknown_number_system_error(number_system)}
        end
    end
  end

  @doc """
  Returns an error tuple for an number system unknown to a given locale.

  ### Arguments

  * `number_system` is any number system name **not** returned by `Cldr.known_number_systems/0`

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
    or a `Cldr.LanguageTag` struct returned by ``Cldr.Locale.new!/2``

  * `valid_number_systems` is a map returned by `Cldr.Number.System.number_systems_for/2`.

  ### Returns

  * `{Cldr.UnknownNumberSystemError, reason}`

  """
  def unknown_number_system_for_locale_error(number_system, locale, valid_number_systems) do
    {
      Cldr.UnknownNumberSystemError,
      "The number system #{inspect(number_system)} is unknown " <>
        "for the locale named #{Cldr.locale_name(locale)}. " <>
        "Valid number systems are #{inspect(valid_number_systems)}"
    }
  end

  @doc false
  def number_system_digits_error(system_name) do
    case number_systems()[system_name] do
      nil ->
        unknown_number_system_error(system_name)

      _system ->
        {
          Cldr.UnknownNumberSystemError,
          "The number system #{inspect(system_name)} does not have digits"
        }
    end
  end

  @doc false
  def algorithmic_system_error(system_name) do
    case number_systems()[system_name] do
      nil ->
        unknown_number_system_error(system_name)

      _system ->
        {
          Cldr.UnknownNumberSystemError,
          "The number system #{inspect(system_name)} is not algorithmic"
        }
    end
  end

  @doc false
  def unknown_number_system_error(system_name) do
    {
      Cldr.UnknownNumberSystemError,
      "The number system #{inspect(system_name)} is not known"
    }
  end
end
