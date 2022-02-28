defmodule Cldr.Number.Format.Meta do
  @moduledoc """
  Describes the metadata that drives
  number formatting and provides functions to
  update the struct.

  ## Format definition

  The `:format` is a keyword list that with two
  elements:

  * `:positive` which is a keyword list for
    formatting a number >= zero

  * `:negative` which is a keyword list for
    formatting negative number

  There are two formats because we can format in
  an accounting style (that is, numbers surrounded
  by `()`) or any other arbitrary style. Typically
  the format for a negative number is the same as
  that for a positive number with a prepended
  minus sign.

  ## Localisation of number formatting

  Number formatting is always localised to either
  the currency processes locale or a locale
  provided as an option to `Cldr.Number.to_string/3`.

  The metadata is independent of the localisation
  process. Signs (`+`/`-`), grouping (`,`), decimal markers
  (`.`) and exponent signs are all localised when
  the number is formatted.

  ## Formatting directives

  The formats - positive and negative - are defined
  in the metadata struct, as a keyword list of keywords
  and values.

  The simplest formatting list might be:
  ```
  [format: _]`
  ```
  The `:format` keyword indicates
  that this is where the formatting number will be
  substituted into the format pattern.

  Another example would be for formatting a negative
  number:
  ```
  [minus: _, format: _]
  ```
  which will format with a localised minus sign
  followed by the formatted number. Note that the
  keyword value for `:minus` and `:format` are
  ignored.

  ## List of formatting keywords

  The following is the full list of formatting
  keywords which can be used to format a
  number. A `_` in the keyword format is
  used to denote `:dont_care`.

  * `[format: _]` inserts the formatted number
    exclusive of any sign

  * `[minus: _]` inserts a localised minus
    sign

  * `[plus: _]` inserts a localised plus sign

  * `[percent: _]` inserts a localised percent sign

  * `[permille: _]` inserts a localised permille sign

  * `[literal: "string"]` inserts `string` into the
    format without any processing

  * `[currency: 1..4]` inserts a localised currency
    symbol of the given `type`.  A `:currency` must be
    provided as an option to `Cldr.Number.Formatter.Decimal.to_string/3`.

  * `[pad: "char"]` inserts the correct number of `char`s
    to pad the number format to the width specified by
    `:padding_length` in the `%Meta{}` struct. The `:pad`
    can be anywhere in the format list but it is most
    typically inserted before or after the `:format`
    keyword.  The assumption is that the `char` is a single
    binary character but this is not checked.

  ## Currency symbol formatting

  Currency are localised and have four ways of being
  presented.  The different types are defined in the
  `[currency: type]` keyword where `type` is an integer
  in the range `1..4`  These types will insert
  into the final format:

    1. The standard currency symbol like `$`,`¥` or `€`
    2. The ISO currency code (like `USD` and `JPY`)
    3. The localised and pluralised currency display name
       like "Australian dollar" or "Australian dollars"
    4. The narrow currency symbol if defined for a locale

  """
  defstruct integer_digits: %{max: 0, min: 1},
            fractional_digits: %{max: 0, min: 0},
            significant_digits: %{max: 0, min: 0},
            exponent_digits: 0,
            exponent_sign: false,
            scientific_rounding: 0,
            grouping: %{
              fraction: %{first: 0, rest: 0},
              integer: %{first: 0, rest: 0}
            },
            round_nearest: 0,
            padding_length: 0,
            padding_char: " ",
            multiplier: 1,
            format: [
              positive: [format: "#"],
              negative: [minus: '-', format: :same_as_positive]
            ],
            number: 0

  @typedoc "Metadata type that drives how to format a number"
  @type t :: %__MODULE__{}

  @doc """
  Returns a new number formatting metadata
  struct.

  """
  @spec new :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Set the minimum, and optionally maximum, integer digits to
  format.

  """
  @spec put_integer_digits(t(), non_neg_integer, non_neg_integer) :: t()
  def put_integer_digits(%__MODULE__{} = meta, min, max \\ 0)
      when is_integer(min) and is_integer(max) do
    meta
    |> Map.put(:integer_digits, %{min: min, max: max})
  end

  @doc """
  Set the minimum, and optionally maximum, fractional digits to
  format.

  """
  @spec put_fraction_digits(t(), non_neg_integer, non_neg_integer) :: t()
  def put_fraction_digits(%__MODULE__{} = meta, min, max \\ 0)
      when is_integer(min) and is_integer(max) do
    meta
    |> Map.put(:fractional_digits, %{min: min, max: max})
  end

  @doc """
  Set the minimum, and optionally maximum, significant digits to
  format.

  """
  @spec put_significant_digits(t(), non_neg_integer, non_neg_integer) :: t()
  def put_significant_digits(%__MODULE__{} = meta, min, max \\ 0)
      when is_integer(min) and is_integer(max) do
    meta
    |> Map.put(:significant_digits, %{min: min, max: max})
  end

  @doc """
  Set the number of exponent digits to
  format.

  """
  @spec put_exponent_digits(t(), non_neg_integer) :: t()
  def put_exponent_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:exponent_digits, digits)
  end

  @doc """
  Set whether to add the sign of the exponent to
  the format.

  """
  @spec put_exponent_sign(t(), boolean) :: t()
  def put_exponent_sign(%__MODULE__{} = meta, flag) when is_boolean(flag) do
    meta
    |> Map.put(:exponent_sign, flag)
  end

  @doc """
  Set the increment to which the number should
  be rounded.

  """
  @spec put_round_nearest_digits(t(), non_neg_integer) :: t()
  def put_round_nearest_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:round_nearest, digits)
  end

  @doc """
  Set the number of scientific digits to which the number should
  be rounded.

  """
  @spec put_scientific_rounding_digits(t(), non_neg_integer) :: t()
  def put_scientific_rounding_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:scientific_rounding, digits)
  end

  @spec put_padding_length(t(), non_neg_integer) :: t()
  def put_padding_length(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:padding_length, digits)
  end

  @doc """
  Set the padding character to be used when
  padding the formatted number.

  """
  @spec put_padding_char(t(), String.t()) :: t()
  def put_padding_char(%__MODULE__{} = meta, char) when is_binary(char) do
    meta
    |> Map.put(:padding_char, char)
  end

  @doc """
  Sets the multiplier for the number.

  Before formatting, the number is multiplied
  by this amount.  This is useful when
  formatting as a percent or permille.

  """
  @spec put_multiplier(t(), non_neg_integer) :: t()
  def put_multiplier(%__MODULE__{} = meta, multiplier) when is_integer(multiplier) do
    meta
    |> Map.put(:multiplier, multiplier)
  end

  @doc """
  Sets the number of digits in a group or
  optionally the first group and subsequent
  groups for the integer part of a number.

  The grouping character is defined by the locale
  defined for the current process or supplied
  as the `:locale` option to `to_string/3`.

  """
  @spec put_integer_grouping(t(), non_neg_integer, non_neg_integer) :: t()
  def put_integer_grouping(%__MODULE__{} = meta, first, rest)
      when is_integer(first) and is_integer(rest) do
    grouping =
      meta
      |> Map.get(:grouping)
      |> Map.put(:integer, %{first: first, rest: rest})

    Map.put(meta, :grouping, grouping)
  end

  @spec put_integer_grouping(t(), non_neg_integer) :: t()
  def put_integer_grouping(%__MODULE__{} = meta, all) when is_integer(all) do
    grouping =
      meta
      |> Map.get(:grouping)
      |> Map.put(:integer, %{first: all, rest: all})

    Map.put(meta, :grouping, grouping)
  end

  @doc """
  Sets the number of digits in a group or
  optionally the first group and subsequent
  groups for the fractional part of a number.

  The grouping character is defined by the locale
  defined for the current process or supplied
  as the `:locale` option to `to_string/3`.

  """
  @spec put_fraction_grouping(t(), non_neg_integer, non_neg_integer) :: t()
  def put_fraction_grouping(%__MODULE__{} = meta, first, rest)
      when is_integer(first) and is_integer(rest) do
    grouping =
      meta
      |> Map.get(:grouping)
      |> Map.put(:fraction, %{first: first, rest: rest})

    Map.put(meta, :grouping, grouping)
  end

  @spec put_fraction_grouping(t(), non_neg_integer) :: t()
  def put_fraction_grouping(%__MODULE__{} = meta, all) when is_integer(all) do
    grouping =
      meta
      |> Map.get(:grouping)
      |> Map.put(:fraction, %{first: all, rest: all})

    Map.put(meta, :grouping, grouping)
  end

  @doc """
  Set the metadata format for the positive
  and negative number format.

  Note that this is the parsed format as a simple keyword
  list, not a binary representation.

  Its up to each formatting engine to transform its input
  into this form.  See `Cldr.Number.Format.Meta` module
  documentation for the available keywords.

  """
  @spec put_format(t(), Keyword.t(), Keyword.t()) :: t()
  def put_format(%__MODULE__{} = meta, positive_format, negative_format) do
    meta
    |> Map.put(:format, positive: positive_format, negative: negative_format)
  end

  @spec put_format(t(), Keyword.t()) :: t()
  def put_format(%__MODULE__{} = meta, positive_format) do
    put_format(meta, positive_format, minus: '-', format: :same_as_positive)
  end
end
