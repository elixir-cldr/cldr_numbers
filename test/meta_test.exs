defmodule Cldr.Number.Format.Meta.Test do
  use ExUnit.Case, async: true

  test "that we can create a default metadata struct" do
    assert Cldr.Number.Format.Meta.new() ==
             %Cldr.Number.Format.Meta{
               exponent_digits: 0,
               exponent_sign: false,
               format: [
                 positive: [format: "#"],
                 negative: [minus: ~c"-", format: :same_as_positive]
               ],
               fractional_digits: %{max: 0, min: 0},
               grouping: %{fraction: %{first: 0, rest: 0}, integer: %{first: 0, rest: 0}},
               integer_digits: %{max: 0, min: 1},
               multiplier: 1,
               number: 0,
               padding_char: " ",
               padding_length: 0,
               round_nearest: 0,
               scientific_rounding: 0,
               significant_digits: %{max: 0, min: 0}
             }
  end

  test "setting the meta fields" do
    alias Cldr.Number.Format.Meta

    meta =
      Meta.new()
      |> Meta.put_integer_digits(2)
      |> Meta.put_fraction_digits(3)
      |> Meta.put_significant_digits(4)

    assert meta.integer_digits == %{max: 0, min: 2}
    assert meta.fractional_digits == %{max: 0, min: 3}
    assert meta.significant_digits == %{max: 0, min: 4}

    meta =
      meta
      |> Meta.put_exponent_digits(5)
      |> Meta.put_exponent_sign(true)
      |> Meta.put_scientific_rounding_digits(6)
      |> Meta.put_round_nearest_digits(7)
      |> Meta.put_padding_length(8)
      |> Meta.put_padding_char("Z")
      |> Meta.put_multiplier(9)

    assert meta.exponent_digits == 5
    assert meta.exponent_sign == true
    assert meta.scientific_rounding == 6
    assert meta.round_nearest == 7
    assert meta.padding_length == 8
    assert meta.padding_char == "Z"
    assert meta.multiplier == 9

    meta =
      meta
      |> Meta.put_fraction_grouping(10)
      |> Meta.put_integer_grouping(11)

    assert meta.grouping == %{
             fraction: %{first: 10, rest: 10},
             integer: %{first: 11, rest: 11}
           }

    meta =
      Meta.new()
      |> Meta.put_integer_digits(12, 13)
      |> Meta.put_fraction_digits(14, 15)
      |> Meta.put_significant_digits(16, 17)

    assert meta.integer_digits == %{max: 13, min: 12}
    assert meta.fractional_digits == %{max: 15, min: 14}
    assert meta.significant_digits == %{max: 17, min: 16}

    meta =
      Meta.new()
      |> Meta.put_format([format: "#"], format: "##")

    assert meta.format == [positive: [format: "#"], negative: [format: "##"]]
  end
end
