defmodule Cldr.Number.Format.Meta do
  defstruct [
    :integer_digits,
    :fractional_digits,
    :significant_digits,
    :exponent_digits,
    :exponent_sign,
    :scientific_rounding,
    :grouping,
    :rounding,
    :padding_length,
    :padding_char,
    :multiplier,
    :format
  ]
end
