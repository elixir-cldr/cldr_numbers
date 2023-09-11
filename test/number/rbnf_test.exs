defmodule Rbnf.Test do
  use ExUnit.Case, async: true

  alias TestBackend.Cldr

  test "rbnf spellout" do
    assert {:ok, "twenty-five thousand three hundred forty"} =
             Cldr.Number.to_string(25_340, format: :spellout)
  end

  test "rbnf spellout in german" do
    assert {:ok, "fünf­und­zwanzig­tausend­drei­hundert­vierzig"} =
             Cldr.Number.to_string(25_340, format: :spellout, locale: "de")
  end

  test "rbnf spellout in french" do
    assert {:ok, "vingt-cinq mille trois cent quarante"} =
             Cldr.Number.to_string(25_340, format: :spellout, locale: "fr")
  end

  test "rbnf spellout in spanish" do
    assert {:ok, "veinticinco mil trescientos cuarenta"} =
             Cldr.Number.to_string(25_340, format: :spellout, locale: "es")
  end

  test "rbnf spellout in mandarin" do
    assert {:ok, "二万五千三百四十"} = Cldr.Number.to_string(25_340, format: :spellout, locale: "zh")
  end

  test "rbnf spellout in hebrew" do
    assert {:ok, "עשרים וחמישה אלף שלוש מאות ארבעים"} =
             Cldr.Number.to_string(25_340, format: :spellout, locale: "he")
  end

  test "rbnf spellout ordinal in de" do
    assert {:ok, "fünf­und­zwanzig­tausend­drei­hundert­vierzigste"} =
             Cldr.Number.to_string(25_340, format: :spellout_ordinal, locale: "de")
  end

  test "rbnf spellout ordinal in ar" do
    assert {:ok, "خمسة وعشرون ألف وثلاثة مائة وأربعون"} =
             Cldr.Number.to_string(25_340, format: :spellout_ordinal_feminine, locale: "ar")

    assert {:ok, "خمسة وعشرون ألف وثلاثة مائة وأربعون"} =
             Cldr.Number.to_string(25_340, format: :spellout_ordinal_masculine, locale: "ar")
  end

  test "rbnf spellout in thai" do
    assert {:ok, "สอง​หมื่น​ห้า​พัน​สาม​ร้อย​สี่​สิบ"} =
             Cldr.Number.to_string(25_340, format: :spellout, locale: "th")
  end

  test "rbnf spellout ordinal verbose" do
    assert {:ok, "one hundred and twenty-three thousand, four hundred and fifty-sixth"} =
             Cldr.Number.to_string(123_456, format: :spellout_ordinal_verbose)
  end

  test "rbnf ordinal" do
    assert {:ok, "123,456th"} = Cldr.Number.to_string(123_456, format: :ordinal)

    assert {:ok, "123 456e"} = Cldr.Number.to_string(123_456, format: :ordinal, locale: "fr")
  end

  test "rbnf improper fraction" do
    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(123.456, "en") ==
             "one hundred and twenty-three point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(-123.456, "en") ==
             "minus one hundred and twenty-three point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(-0.456, "en") ==
             "minus zero point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal_verbose(0.456, "en") == "zero point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal(0.456, "en") == "zero point four five six"

    assert Cldr.Rbnf.Spellout.spellout_cardinal(0, "en") == "zero"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(0, "en") == "zeroth"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(0.0, "en") == "0"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(0.1, "en") == "0.1"
  end

  test "decimal rbnf for decimal integers" do
    assert {:ok, "123,456th"} = Cldr.Number.to_string(Decimal.new(123_456), format: :ordinal)

    assert {:ok, "123 456e"} =
             Cldr.Number.to_string(
               Decimal.new(123_456),
               format: :ordinal,
               locale: "fr"
             )

    assert {:ok, "one hundred and twenty-three thousand, four hundred and fifty-sixth"} =
             Cldr.Number.to_string(Decimal.new(123_456), format: :spellout_ordinal_verbose)

    assert {:ok, "twenty-five thousand three hundred forty"} =
             Cldr.Number.to_string(Decimal.new(25_340), format: :spellout)

    assert Cldr.Rbnf.Spellout.spellout_cardinal(Decimal.new(0), "en") == "zero"
    assert Cldr.Rbnf.Spellout.spellout_ordinal(Decimal.new(0), "en") == "zeroth"
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
    assert Cldr.Rbnf.Spellout.spellout_numbering_year(-24, "zh-Hant") ==
             {
               :error,
               {
                 Elixir.Cldr.Rbnf.NoRuleForNumber,
                 "rule group :spellout_numbering_year for locale :\"zh-Hant\" does not know how to process -24"
               }
             }
  end

  test "that rbnf rules lookup fall back to the root locale (und)" do
    # implemented in und locale
    assert Cldr.Number.to_string(123, format: :digits_ordinal, locale: "de") ==
             {:ok, "123."}

    # implemented in en locale
    assert Cldr.Number.to_string(123, format: :digits_ordinal, locale: "en") ==
             {:ok, "123rd"}
  end

  test "RBNF Spellout for spanish" do
    assert TestBackend.Cldr.Number.to_string(123.456, format: :spellout_cardinal_masculine, locale: :es) ==
      {:ok, "ciento veintitrés punto cuatro cinco seis"}

    assert TestBackend.Cldr.Number.to_string(123.456, format: :spellout_cardinal_feminine, locale: :es) ==
      {:ok, "ciento veintitrés punto cuatro cinco seis"}
  end

  Elixir.Cldr.Rbnf.TestSupport.rbnf_tests(fn name, tests, module, function, locale ->
    test name do
      Enum.each(unquote(Macro.escape(tests)), fn {test_data, test_result} ->
        if apply(unquote(module), unquote(function), [
             String.to_integer(test_data),
             unquote(Macro.escape(locale))
           ]) != test_result do
          IO.puts(
            "Test is failing on locale #{unquote(locale.requested_locale_name)} for value #{test_data}"
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
