defmodule Rbnf.Test do
  use ExUnit.Case
  alias Cldr.Locale

  test "rbnf spellout" do
    assert {:ok, "twenty-five thousand three hundred forty"} =
             Cldr.Number.to_string(25_340, format: :spellout)
  end

  test "rbnf spellout ordinal verbose" do
    assert {:ok, "one hundred and twenty-three thousand, four hundred and fifty-sixth"} =
             Cldr.Number.to_string(123_456, format: :spellout_ordinal_verbose)
  end

  test "rbnf ordinal" do
    assert {:ok, "123,456th"} = Cldr.Number.to_string(123_456, format: :ordinal)

    assert {:ok, "123 456e"} =
             Cldr.Number.to_string(123_456, format: :ordinal, locale: Locale.new!("fr"))
  end

  test "rbnf improper fraction" do
    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(123.456, Locale.new!("en")) ==
             "one hundred and twenty-three point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(-123.456, Locale.new!("en")) ==
             "minus one hundred and twenty-three point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(-0.456, Locale.new!("en")) ==
             "minus zero point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(0.456, Locale.new!("en")) ==
             "zero point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal(0.456, Locale.new!("en")) ==
             "zero point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal(0, Locale.new!("en")) == "zero"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(0, Locale.new!("en")) == "zeroth"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(0.0, Locale.new!("en")) == "0"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(0.1, Locale.new!("en")) == "0.1"
  end

  test "decimal rbnf for decimal integers" do
    assert {:ok, "123,456th"} = Cldr.Number.to_string(Decimal.new(123_456), format: :ordinal)

    assert {:ok, "123 456e"} =
             Cldr.Number.to_string(
               Decimal.new(123_456),
               format: :ordinal,
               locale: Locale.new!("fr")
             )

    assert {:ok, "one hundred and twenty-three thousand, four hundred and fifty-sixth"} =
             Cldr.Number.to_string(Decimal.new(123_456), format: :spellout_ordinal_verbose)

    assert {:ok, "twenty-five thousand three hundred forty"} =
             Cldr.Number.to_string(Decimal.new(25_340), format: :spellout)

    assert Cldr.Rbnf.Spellout.spellout_cardinal(Decimal.new(0), Locale.new!("en")) == "zero"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(Decimal.new(0), Locale.new!("en")) == "zeroth"
  end

  test "roman numerals" do
    assert Cldr.Number.to_string(1, format: :roman) == {:ok, "I"}
    assert Cldr.Number.to_string(2, format: :roman) == {:ok, "II"}
    assert Cldr.Number.to_string(3, format: :roman) == {:ok, "III"}
    assert Cldr.Number.to_string(4, format: :roman) == {:ok, "IV"}
    assert Cldr.Number.to_string(5, format: :roman) == {:ok, "V"}
    assert Cldr.Number.to_string(6, format: :roman) == {:ok, "VI"}
    assert Cldr.Number.to_string(7, format: :roman) == {:ok, "VII"}
    assert Cldr.Number.to_string(8, format: :roman) == {:ok, "VIII"}
    assert Cldr.Number.to_string(9, format: :roman) == {:ok, "IX"}
    assert Cldr.Number.to_string(10, format: :roman) == {:ok, "X"}
    assert Cldr.Number.to_string(11, format: :roman) == {:ok, "XI"}
    assert Cldr.Number.to_string(20, format: :roman) == {:ok, "XX"}
    assert Cldr.Number.to_string(50, format: :roman) == {:ok, "L"}
    assert Cldr.Number.to_string(90, format: :roman) == {:ok, "XC"}
    assert Cldr.Number.to_string(100, format: :roman) == {:ok, "C"}
    assert Cldr.Number.to_string(1000, format: :roman) == {:ok, "M"}
    assert Cldr.Number.to_string(123, format: :roman) == {:ok, "CXXIII"}
  end

  test "no rule is available for number" do
    assert Cldr.Rbnf.Spellout.spellout_numbering_year(-24, Cldr.Locale.new!("zh-Hant")) ==
             {
               :error,
               {
                 Cldr.Rbnf.NoRuleForNumber,
                 "rule group :spellout_numbering_year for locale \"zh-Hant\" does not know how to process -24"
               }
             }
  end

  Cldr.Rbnf.TestSupport.rbnf_tests(fn name, tests, module, function, locale ->
    test name do
      Enum.each(unquote(Macro.escape(tests)), fn {test_data, test_result} ->
        if apply(unquote(module), unquote(function), [
             String.to_integer(test_data),
             unquote(Macro.escape(locale))
           ]) != test_result do
          IO.puts(
            "Test is failing on locale #{unquote(locale.requested_locale_name)} for value #{
              test_data
            }"
          )
        end

        assert apply(unquote(module), unquote(function), [
                 String.to_integer(test_data),
                 unquote(Macro.escape(locale))
               ]) == test_result
      end)
    end
  end)
end
