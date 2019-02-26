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
end
