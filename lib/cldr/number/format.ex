defmodule Cldr.Number.Format do
  @moduledoc """
  Functions to manage the collection of number patterns defined in Cldr.

  Number patterns affect how numbers are interpreted in a localized context.
  Here are some examples, based on the French locale. The "." shows where the
  decimal point should go. The "," shows where the thousands separator should
  go. A "0" indicates zero-padding: if the number is too short, a zero (in the
  locale's numeric set) will go there. A "#" indicates no padding: if the
  number is too short, nothing goes there. A "¤" shows where the currency sign
  will go. The following illustrates the effects of different patterns for the
  French locale, with the number "1234.567". Notice how the pattern characters
  ',' and '.' are replaced by the characters appropriate for the locale.

  ## Number Pattern Examples

  | Pattern	      | Currency	      | Text        |
  | ------------- | :-------------: | ----------: |
  | #,##0.##	    | n/a	            | 1 234,57    |
  | #,##0.###	    | n/a	            | 1 234,567   |
  | ###0.#####	  | n/a	            | 1234,567    |
  | ###0.0000#	  | n/a	            | 1234,5670   |
  | 00000.0000	  | n/a	            | 01234,5670  |
  | #,##0.00 ¤	  | EUR	            | 1 234,57 €  |

  The number of # placeholder characters before the decimal do not matter,
  since no limit is placed on the maximum number of digits. There should,
  however, be at least one zero some place in the pattern. In currency formats,
  the number of digits after the decimal also do not matter, since the
  information in the supplemental data (see Supplemental Currency Data) is used
  to override the number of decimal places — and the rounding — according to
  the currency that is being formatted. That can be seen in the above chart,
  with the difference between Yen and Euro formatting.

  Details of the number formats are described in the
  [Unicode documentation](http://unicode.org/reports/tr35/tr35-numbers.html#Number_Format_Patterns)

  """

  @type format :: String.t()
  @short_format_styles [:decimal_long, :decimal_short, :currency_short, :currency_long]

  @format_styles [:standard, :currency, :accounting, :scientific, :percent] ++
                   @short_format_styles

  defstruct @format_styles ++ [:currency_spacing, :other]

  require Cldr
  alias Cldr.Number.System
  alias Cldr.Locale
  alias Cldr.LanguageTag

  def short_format_styles do
    @short_format_styles
  end

  @doc """
  Returns the list of decimal formats in the configured locales including
  the list of locales configured for precompilation in `config.exs`.

  This function exists to allow the decimal formatter
  to precompile all the known formats at compile time.

  ## Arguments

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Example

      => Cldr.Number.Format.decimal_format_list(MyApp.Cldr)
      ["#", "#,##,##0%", "#,##,##0.###", "#,##,##0.00¤", "#,##,##0.00¤;(#,##,##0.00¤)",
      "#,##,##0 %", "#,##0%", "#,##0.###", "#,##0.00 ¤",
      "#,##0.00 ¤;(#,##0.00 ¤)", "#,##0.00¤", "#,##0.00¤;(#,##0.00¤)",
      "#,##0 %", "#0%", "#0.######", "#0.00 ¤", "#E0", "%#,##0", "% #,##0",
      "0", "0.000000E+000", "0000 M ¤", "0000¤", "000G ¤", "000K ¤", "000M ¤",
      "000T ¤", "000mM ¤", "000m ¤", "000 Bio'.' ¤", "000 Bln ¤", "000 Bn ¤",
      "000 B ¤", "000 E ¤", "000 K ¤", "000 MRD ¤", "000 Md ¤", "000 Mio'.' ¤",
      "000 Mio ¤", "000 Mld ¤", "000 Mln ¤", "000 Mn ¤", "000 Mrd'.' ¤",
      "000 Mrd ¤", "000 Mr ¤", "000 M ¤", "000 NT ¤", "000 N ¤", "000 Tn ¤",
      "000 Tr ¤", ...]

  """

  @spec decimal_format_list(Cldr.backend()) :: list(format())
  def decimal_format_list(backend) do
    Module.concat(backend, Number.Format).decimal_format_list
  end

  @doc """
  Returns the list of decimal formats for a configured locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  This function exists to allow the decimal formatter to precompile all
  the known formats at compile time. Its use is not otherwise recommended.

  ## Example

      iex> Cldr.Number.Format.decimal_format_list_for("en", MyApp.Cldr)
      {:ok, ["#,##0%", "#,##0.###", "#,##0.00", "#,##0.00;(#,##0.00)","#E0",
       "0 billion", "0 million", "0 thousand",
       "0 trillion", "00 billion", "00 million", "00 thousand", "00 trillion",
       "000 billion", "000 million", "000 thousand", "000 trillion", "000B", "000K",
       "000M", "000T", "00B", "00K", "00M", "00T", "0B", "0K", "0M", "0T",
       "¤#,##0.00", "¤#,##0.00;(¤#,##0.00)", "¤000B", "¤000K", "¤000M",
       "¤000T", "¤00B", "¤00K", "¤00M", "¤00T", "¤0B", "¤0K", "¤0M", "¤0T",
       "¤ #,##0.00", "¤ #,##0.00;(¤ #,##0.00)", "¤ 000B", "¤ 000K", "¤ 000M",
       "¤ 000T", "¤ 00B", "¤ 00K", "¤ 00M", "¤ 00T", "¤ 0B", "¤ 0K", "¤ 0M", "¤ 0T"]}

  """
  @spec decimal_format_list_for(LanguageTag.t() | Locale.locale_name(), Cldr.backend()) ::
          {:ok, list(String.t())} | {:error, {module(), String.t()}}

  def decimal_format_list_for(locale, backend) do
    Module.concat(backend, Number.Format).decimal_format_list_for(locale)
  end

  @doc """
  Returns the decimal formats defined for a given locale.

  ## Options

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Examples

      Cldr.Number.Format.all_formats_for("en", MyApp.Cldr)
      #=> {:ok, %{latn: %Cldr.Number.Format{
        accounting: "¤#,##0.00;(¤#,##0.00)",
        currency: "¤#,##0.00",
        percent: "#,##0%",
        scientific: "#E0",
        standard: "#,##0.###",
        currency_short: [{"1000", [one: "¤0K", other: "¤0K"]},
         {"10000", [one: "¤00K", other: "¤00K"]},
         {"100000", [one: "¤000K", other: "¤000K"]},
         {"1000000", [one: "¤0M", other: "¤0M"]},
         {"10000000", [one: "¤00M", other: "¤00M"]},
         {"100000000", [one: "¤000M", other: "¤000M"]},
         {"1000000000", [one: "¤0B", other: "¤0B"]},
         {"10000000000", [one: "¤00B", other: "¤00B"]},
         {"100000000000", [one: "¤000B", other: "¤000B"]},
         {"1000000000000", [one: "¤0T", other: "¤0T"]},
         {"10000000000000", [one: "¤00T", other: "¤00T"]},
         {"100000000000000", [one: "¤000T", other: "¤000T"]}],
         ....
        }}
  """

  @spec all_formats_for(LanguageTag.t() | Locale.locale_name(), Cldr.backend()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def all_formats_for(locale, backend) do
    Module.concat(backend, Number.Format).all_formats_for(locale)
  end

  @doc """
  Returns the decimal formats defined for a given locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Returns

  * a list of decimal formats or

  * raises an exception

  See `Cldr.Number.Format.all_formats_for/2` for further information.

  """
  def all_formats_for!(locale, backend) do
    Module.concat(backend, Number.Format).all_formats_for!(locale)
  end

  @doc """
  Returns the minimum grouping digits for a locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/0`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Returns

  * `{:ok, minumum_digits}` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Number.Format.minimum_grouping_digits_for("en", MyApp.Cldr)
      {:ok, 1}

  """
  @spec minimum_grouping_digits_for(LanguageTag.t(), Cldr.backend()) ::
          {:ok, non_neg_integer} | {:error, {module(), String.t()}}

  def minimum_grouping_digits_for(locale, backend) do
    Module.concat(backend, Number.Format).minimum_grouping_digits_for(locale)
  end

  @doc """
  Returns the minimum grouping digits for a locale or raises if there is an error.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Examples

      iex> Cldr.Number.Format.minimum_grouping_digits_for!("en", MyApp.Cldr)
      1

      Cldr.Number.Format.minimum_grouping_digits_for!(:invalid)
      ** (Cldr.UnknownLocaleError) The locale :invalid is invalid

  """
  def minimum_grouping_digits_for!(locale, backend) do
    Module.concat(backend, Number.Format).minimum_grouping_digits_for!(locale)
  end

  @doc """
  Returns the default grouping for a locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/0`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Returns

  * `{:ok, minumum_digits}` or

  * `{:error, {exception, message}}`

  ## Examples

      iex> Cldr.Number.Format.default_grouping_for("en", MyApp.Cldr)
      {:ok, %{fraction: %{first: 0, rest: 0}, integer: %{first: 3, rest: 3}}}

  """
  @spec default_grouping_for(LanguageTag.t() | Cldr.Locale.locale_name(), Cldr.backend()) ::
          {:ok, non_neg_integer} | {:error, {module(), String.t()}}

  def default_grouping_for(locale, backend) do
    Module.concat(backend, Number.Format).default_grouping_for(locale)
  end

  @doc """
  Returns the default grouping for a locale or raises if there is an error.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Examples

      iex> Cldr.Number.Format.default_grouping_for!("en", MyApp.Cldr)
      %{fraction: %{first: 0, rest: 0}, integer: %{first: 3, rest: 3}}

      Cldr.Number.Format.default_grouping_for!(:invalid)
      ** (Cldr.UnknownLocaleError) The locale :invalid is invalid

  """
  @spec default_grouping_for!(LanguageTag.t() | Cldr.Locale.locale_name(), Cldr.backend()) ::
          map() | no_return

  def default_grouping_for!(locale, backend) do
    Module.concat(backend, Number.Format).default_grouping_for!(locale)
  end

  @doc """
  Returns the currency space for a given locale and
  number system.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `number_system` is any valid number system or number system type returned
    by `Cldr.Number.System.number_systems_for/2`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  """
  @spec currency_spacing(
          LanguageTag.t() | Cldr.Locale.locale_name(),
          System.system_name(),
          Cldr.backend()
        ) :: map() | {:error, {module(), String.t()}}

  def currency_spacing(locale, number_system, backend) do
    backend.currency_spacing(locale, number_system)
  end

  @doc """
  Return the predfined formats for a given `locale` and `number_system`.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `number_system` is any valid number system or number system type returned
    by `Cldr.Number.System.number_systems_for/2` or `Cldr.Number.System.number_system_names_for/2`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Example

      Cldr.Number.Format.formats_for "fr", :native, MyApp.Cldr
      #=> {:ok, %Cldr.Number.Format{
        accounting: "#,##0.00 ¤;(#,##0.00 ¤)",
        currency: "#,##0.00 ¤",
        percent: "#,##0 %",
        scientific: "#E0",
        standard: "#,##0.###"
        currency_short: [{"1000", [one: "0 k ¤", other: "0 k ¤"]},
         {"10000", [one: "00 k ¤", other: "00 k ¤"]},
         {"100000", [one: "000 k ¤", other: "000 k ¤"]},
         {"1000000", [one: "0 M ¤", other: "0 M ¤"]},
         {"10000000", [one: "00 M ¤", other: "00 M ¤"]},
         {"100000000", [one: "000 M ¤", other: "000 M ¤"]},
         {"1000000000", [one: "0 Md ¤", other: "0 Md ¤"]},
         {"10000000000", [one: "00 Md ¤", other: "00 Md ¤"]},
         {"100000000000", [one: "000 Md ¤", other: "000 Md ¤"]},
         {"1000000000000", [one: "0 Bn ¤", other: "0 Bn ¤"]},
         {"10000000000000", [one: "00 Bn ¤", other: "00 Bn ¤"]},
         {"100000000000000", [one: "000 Bn ¤", other: "000 Bn ¤"]}],
         ...
        }}

  """
  @spec formats_for(LanguageTag.t() | Locale.locale_name(), atom | String.t(), Cldr.backend()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def formats_for(locale, number_system, backend) do
    Module.concat(backend, Number.Format).formats_for(locale, number_system)
  end

  @doc """
  Return the predfined formats for a given `locale` and `number_system` or raises
  if either the `locale` or `number_system` is invalid.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `number_system` is any valid number system or number system type returned
    by `Cldr.Number.System.number_systems_for/2`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  """
  @spec formats_for!(LanguageTag.t(), Cldr.Number.System.system_name(), Cldr.backend()) ::
          map() | no_return()

  def formats_for!(locale, number_system, backend) do
    case formats_for(locale, number_system, backend) do
      {:ok, formats} -> formats
      {:error, {exception, message}} -> raise exception, message
    end
  end

  @doc """
  Returns the format styles available for a `locale`.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `number_system` is any valid number system or number system type returned
    by `Cldr.Number.System.number_systems_for/2`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  Format styles standardise the access to a format defined for a common
  use.  These types are `:standard`, `:currency`, `:accounting`, `:scientific`
  and :percent, :currency_short, :decimal_short, :decimal_long.

  These types can be used when formatting a number for output.  For example
  `Cldr.Number.to_string(123.456, format: :percent)`.

  ## Example

      iex> Cldr.Number.Format.format_styles_for("en", :latn, MyApp.Cldr)
      {:ok, [:accounting, :currency, :currency_long, :currency_short,
      :decimal_long, :decimal_short, :percent, :scientific, :standard]}

  """
  @reject_styles [:__struct__, :currency_spacing, :other]
  @spec format_styles_for(
          LanguageTag.t() | Locale.locale_name(),
          System.system_name(),
          Cldr.backend()
        ) :: {:ok, list(atom())} | {:error, {module(), String.t()}}

  def format_styles_for(%LanguageTag{} = locale, number_system, backend) do
    with {:ok, formats} <- formats_for(locale, number_system, backend) do
      {
        :ok,
        formats
        |> Map.to_list()
        |> Enum.reject(fn {k, v} -> is_nil(v) || k in @reject_styles end)
        |> Enum.into(%{})
        |> Map.keys()
      }
    end
  end

  def format_styles_for(locale_name, number_system, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      format_styles_for(locale, number_system, backend)
    end
  end

  @doc """
  Returns the short formats available for a locale.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `number_system` is any valid number system or number system type returned
    by `Cldr.Number.System.number_systems_for/2`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Example

      iex> Cldr.Number.Format.short_format_styles_for("he", :latn, MyApp.Cldr)
      {:ok, [:currency_short, :decimal_long, :decimal_short]}

  """
  @isnt_really_a_short_format [:currency_long]
  @short_formats MapSet.new(@short_format_styles -- @isnt_really_a_short_format)

  @spec short_format_styles_for(
          LanguageTag.t() | Cldr.Locale.locale_name(),
          binary | atom,
          Cldr.backend()
        ) ::
          {:ok, list(atom())} | {:error, {module(), String.t()}}

  @dialyzer {:nowarn_function, short_format_styles_for: 3}

  def short_format_styles_for(%LanguageTag{} = locale, number_system, backend) do
    with {:ok, formats} <- format_styles_for(locale, number_system, backend) do
      {
        :ok,
        formats
        |> MapSet.new()
        |> MapSet.intersection(@short_formats)
        |> MapSet.to_list()
      }
    end
  end

  def short_format_styles_for(locale_name, number_system, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      short_format_styles_for(locale, number_system, backend)
    end
  end

  @doc """
  Returns the decimal format styles that are supported by
  `Cldr.Number.Formatter.Decimal`.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `number_system` is any valid number system or number system type returned
    by `Cldr.Number.System.number_systems_for/2`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Example

      iex> Cldr.Number.Format.decimal_format_styles_for("en", :latn, MyApp.Cldr)
      {:ok, [:accounting, :currency, :currency_long, :percent,
       :scientific, :standard]}

  """
  @spec decimal_format_styles_for(
          LanguageTag.t() | Locale.locale_name(),
          System.system_name(),
          Cldr.backend()
        ) :: {:ok, list(atom())} | {:error, {module(), String.t()}}

  @dialyzer {:nowarn_function, decimal_format_styles_for: 3}

  def decimal_format_styles_for(%LanguageTag{} = locale, number_system, backend) do
    with {:ok, styles} <- format_styles_for(locale, number_system, backend),
         {:ok, short_styles} <- short_format_styles_for(locale, number_system, backend) do
      {:ok, styles -- short_styles -- [:currency_long, :currency_spacing, :other]}
    end
  end

  def decimal_format_styles_for(locale_name, number_system, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      decimal_format_styles_for(locale, number_system, backend)
    end
  end

  @doc """
  Returns the number system types available for a `locale`

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  A number system type is an identifier that categorises number systems
  that comprise a site of digits or rules for transliterating or translating
  digits and a number system name for determining plural rules and format
  masks.

  If that all sounds a bit complicated then the default `number system type`
  called `:default` is probably what you want nearly all the time.

  ## Examples

      iex> Cldr.Number.Format.format_system_types_for("pl", MyApp.Cldr)
      {:ok, [:default, :native]}

      iex> Cldr.Number.Format.format_system_types_for("ru", MyApp.Cldr)
      {:ok, [:default, :native]}

      iex> Cldr.Number.Format.format_system_types_for("th", MyApp.Cldr)
      {:ok, [:default, :native]}

  """
  @spec format_system_types_for(Cldr.Locale.locale_name() | LanguageTag.t(), Cldr.backend()) ::
          {:ok, Keyword.t()} | {:error, {module(), String.t()}}

  def format_system_types_for(%LanguageTag{} = locale, backend) do
    with {:ok, _} <- Cldr.validate_locale(locale, backend) do
      {:ok, systems} = System.number_systems_for(locale, backend)
      {:ok, Map.keys(systems)}
    end
  end

  def format_system_types_for(locale_name, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      format_system_types_for(locale, backend)
    end
  end

  @doc """
  Returns the names of the number systems for the `locale`.

  ## Arguments

  * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
    or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
    is `Cldr.get_locale/1`

  * `backend` is any `Cldr` backend. That is, any module that
    contains `use Cldr`

  ## Examples

      iex> Cldr.Number.Format.format_system_names_for("th", MyApp.Cldr)
      {:ok, [:latn, :thai]}

      iex> Cldr.Number.Format.format_system_names_for("pl", MyApp.Cldr)
      {:ok, [:latn]}

  """
  @spec format_system_names_for(LanguageTag.t() | Cldr.Locale.locale_name(), Cldr.backend()) ::
          {:ok, list(atom)} | {:error, {module(), String.t()}}

  def format_system_names_for(%LanguageTag{} = locale, backend) do
    Cldr.Number.System.number_system_names_for(locale, backend)
  end

  def format_system_names_for(locale_name, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale_name, backend) do
      format_system_names_for(locale, backend)
    end
  end
end
