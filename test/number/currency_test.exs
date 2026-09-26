defmodule Cldr.Number.CurrencyTest do
  use ExUnit.Case, async: true

  test "That the currency is derived from the locale" do
    assert {:ok, "AU$๑๒๓.๐๐"} ==
             MyApp.Cldr.Number.to_string(123,
               locale: "th-u-cu-aud-nu-thai",
               currency: :from_locale
             )

    assert {:ok, "฿๑๒๓.๐๐"} ==
             MyApp.Cldr.Number.to_string(123, locale: "th-u-nu-thai", currency: :from_locale)

    assert {:ok, "฿123.00"} ==
             MyApp.Cldr.Number.to_string(123, locale: "th", currency: :from_locale)
  end

  test "fr-CH formats 1234.56 CHF with a . decimal separator but 1234.56 with a ," do
    {:ok, symbols} = Cldr.Number.Symbol.number_symbols_for("fr-CH", :latn, TestBackend.Cldr)
    group = symbols.group.standard
    options = [locale: "fr-CH", currency: :CHF]

    assert {:ok, "1#{group}234.56 CHF"} ==
             TestBackend.Cldr.Number.to_string(1234.56, options)

    assert {:ok, "(1#{group}234.56 CHF)"} ==
             TestBackend.Cldr.Number.to_string(-1234.56, [format: :accounting] ++ options)

    assert {:ok, "1#{group}234.56 francs suisses"} ==
             TestBackend.Cldr.Number.to_string(
               1234.56,
               [format: :currency_long, fractional_digits: 2] ++ options
             )

    assert {:ok, "1#{group}234.56"} ==
             TestBackend.Cldr.Number.to_string(1234.56, [currency_symbol: :none] ++ options)

    assert {:ok, "1#{group}234,56"} ==
             TestBackend.Cldr.Number.to_string(1234.56, locale: "fr-CH")
  end

  test "de-AT formats 1234.56 EUR with a . group separator but 1234.56 without" do
    {:ok, symbols} = Cldr.Number.Symbol.number_symbols_for("de-AT", :latn, TestBackend.Cldr)

    assert {:ok, "€ 1.234,56"} ==
             TestBackend.Cldr.Number.to_string(1234.56, locale: "de-AT", currency: :EUR)

    assert {:ok, "1#{symbols.group.standard}234,56"} ==
             TestBackend.Cldr.Number.to_string(1234.56, locale: "de-AT")
  end
end
