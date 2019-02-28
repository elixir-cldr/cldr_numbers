defmodule Cldr.Number.Format.Meta do
  @moduledoc """
  Describes the metadata that drives
  number formatting and provides functions to
  update the struct.

  """
  defstruct [
    integer_digits: %{max: 0, min: 1},
    fractional_digits: %{max: 0, min: 0},
    significant_digits: %{max: 0, min: 0},
    exponent_digits: 0,
    exponent_sign: false,
    scientific_rounding: 0,
    grouping: %{
      fraction: %{first: 0, rest: 0},
      integer: %{first: 0, rest: 0}
    },
    rounding: 0,
    padding_length: 0,
    padding_char: " ",
    multiplier: 1,
    format: [
      positive: [format: "#"],
      negative: [minus: '-', format: :same_as_positive]
      ],
    number: 0
  ]

  @doc """
  Returns a new number formatting metadata
  struct.

  """
  def new do
    %__MODULE__{}
  end

  @doc """
  Set the minimum, and optionally maximum, integer digits to
  format.

  """
  def put_integer_digits(%__MODULE__{} = meta, min, max \\ 0) when is_integer(min) and is_integer(max) do
    meta
    |> Map.put(:integer_digits, %{min: min, max: max})
  end

  @doc """
  Set the minimum, and optionally maximum, fractional digits to
  format.

  """
  def put_fraction_digits(%__MODULE__{} = meta, min, max \\ 0) when is_integer(min) and is_integer(max) do
    meta
    |> Map.put(:fractional_digits, %{min: min, max: max})
  end

  @doc """
  Set the minimum, and optionally maximum, significant digits to
  format.

  """
  def put_significant_digits(%__MODULE__{} = meta, min, max \\ 0) when is_integer(min) and is_integer(max) do
    meta
    |> Map.put(:significant_digits, %{min: min, max: max})
  end

  @doc """
  Set the number of exponent digits to
  format.

  """
  def put_exponent_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:exponent_digits, digits)
  end

  @doc """
  Set whether to add the sign of the exponent to
  the format.

  """
  def put_exponent_sign(%__MODULE__{} = meta, flag) when is_boolean(flag) do
    meta
    |> Map.put(:exponent_sign, flag)
  end

  @doc """
  Set the number of digits to which the number should
  be rounded.

  """
  def put_rounding_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:rounding, digits)
  end

  @doc """
  Set the number of scientific digits to which the number should
  be rounded.

  """
  def put_scientific_rounding_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:scientific_rounding, digits)
  end

  def put_padding_length(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:padding_length, digits)
  end

  @doc """
  Set the padding character to be used when
  padding the formatted number.

  """
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
  def put_integer_grouping(%__MODULE__{} = meta, first, rest) when is_integer(first) and is_integer(rest) do
    grouping =
      meta
      |> Map.get(:grouping)
      |> Map.put(:integer, %{first: first, rest: rest})

    Map.put(meta, :grouping, grouping)
  end

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
  def put_fraction_grouping(%__MODULE__{} = meta, first, rest) when is_integer(first) and is_integer(rest) do
    grouping =
      meta
      |> Map.get(:grouping)
      |> Map.put(:fraction, %{first: first, rest: rest})

    Map.put(meta, :grouping, grouping)
  end

  def put_fraction_grouping(%__MODULE__{} = meta, all) when is_integer(all) do
    grouping =
      meta
      |> Map.get(:grouping)
      |> Map.put(:fraction, %{first: all, rest: all})

    Map.put(meta, :grouping, grouping)
  end

end
