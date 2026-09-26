defmodule Number.Symbol.Test do
  use ExUnit.Case, async: true

  test "that we can get number symbols for a known locale" do
    {:ok, symbols} = TestBackend.Cldr.Number.Symbol.number_symbols_for("en", "latn")

    assert symbols ==
                %Cldr.Number.Symbol{
                  approximately_sign: "~",
                  decimal: %{standard: "."},
                  exponential: "E",
                  group: %{standard: ","},
                  infinity: "∞",
                  list: ";",
                  minus_sign: "-",
                  nan: "NaN",
                  per_mille: "‰",
                  percent_sign: "%",
                  plus_sign: "+",
                  superscripting_exponent: "×",
                  time_separator: ":"
                }
  end

  test "nb's latn symbols keep the approximately sign \"ca.\" and leave out the alternative time separator \".\"" do
    {:ok, symbols} = TestBackend.Cldr.Number.Symbol.number_symbols_for("nb", :latn)

    assert %Cldr.Number.Symbol{approximately_sign: "ca.", time_separator: ":"} = symbols
  end

  test "a CLDR number symbol that Cldr.Number.Symbol does not know raises" do
    assert_raise KeyError, ~r/key :digit_marker not found/, fn ->
      Cldr.Number.Symbol.new!(%{decimal: %{standard: "."}, digit_marker: "#"})
    end
  end

  test "that we raise an error if we get minimum digits for an invalid locale" do
    assert_raise Cldr.InvalidLanguageError, ~r/The language .* is invalid/, fn ->
      TestBackend.Cldr.Number.Format.minimum_grouping_digits_for!("zzzzz")
    end
  end
end
