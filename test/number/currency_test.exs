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
end
