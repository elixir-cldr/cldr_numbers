defmodule Cldr.Number.Format.Meta do
  @moduledoc """
  Describes the metadata that drives
  number formatting

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

  def put_integer_digits(%__MODULE__{} = meta, min, max \\ 0) when is_integer(min) and is_integer(max) do
    meta
    |> Map.put(:integer_digits, %{min: min, max: max})
  end

  def put_fraction_digits(%__MODULE__{} = meta, min, max \\ 0) do
    meta
    |> Map.put(:fraction_digits, %{min: min, max: max})
  end

  def put_exponent_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:exponent_digits, digits)
  end

  def put_exponent_sign(%__MODULE__{} = meta, flag) when is_boolean(flag) do
    meta
    |> Map.put(:exponent_sign, flag)
  end

  def put_rounding_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:rounding, digits)
  end

  def put_scientific_rounding_digits(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:scientific_rounding, digits)
  end

  def put_padding_length(%__MODULE__{} = meta, digits) when is_integer(digits) do
    meta
    |> Map.put(:padding_length, digits)
  end

  def put_padding_char(%__MODULE__{} = meta, char) when is_binary(char) do
    meta
    |> Map.put(:padding_char, char)
  end

  def put_multiplier(%__MODULE__{} = meta, multiplier) when is_integer(multiplier) do
    meta
    |> Map.put(:miltiplier, multiplier)
  end

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
