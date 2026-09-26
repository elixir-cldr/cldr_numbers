defmodule Cldr.Number.ApproximatelyTest do
  use ExUnit.Case, async: true

  # The expected strings match ICU's approximate format, for example
  # `new Intl.NumberFormat("fr-BE").formatRange(1234, 1234)` in Node.

  test "fr-BE formats approximately 1234 as \"≃1 234\" and -1234 as \"≃-1 234\"" do
    assert {:ok, "≃1 234"} == TestBackend.Cldr.Number.to_approx_string(1234, locale: "fr-BE")
    assert {:ok, "≃-1 234"} == TestBackend.Cldr.Number.to_approx_string(-1234, locale: "fr-BE")
  end

  test "nb formats approximately 1234 as \"ca.1 234\" and -1234 as \"ca.−1 234\"" do
    assert {:ok, "ca.1 234"} == TestBackend.Cldr.Number.to_approx_string(1234, locale: "nb")
    assert {:ok, "ca.−1 234"} == TestBackend.Cldr.Number.to_approx_string(-1234, locale: "nb")
  end

  test "en formats approximately 0 as \"~0\"" do
    assert {:ok, "~0"} == TestBackend.Cldr.Number.to_approx_string(0, locale: "en")
  end

  test "en formats approximately 1234 US dollars in the long currency format as \"~1,234.00 US dollars\"" do
    assert {:ok, "~1,234.00 US dollars"} ==
             TestBackend.Cldr.Number.to_approx_string(1234,
               locale: "en",
               currency: :USD,
               format: :currency_long,
               fractional_digits: 2
             )
  end

  # Spellout and roman have no sign position, so they keep the
  # "approximately" pattern ("ca. {0}" in nb).
  test "nb spells out approximately 12 as \"ca. tolv\"" do
    assert {:ok, "ca. tolv"} ==
             TestBackend.Cldr.Number.to_approx_string(12, locale: "nb", format: :spellout)
  end

  test "nb formats approximately 12 in roman numerals as \"ca. XII\"" do
    assert {:ok, "ca. XII"} ==
             TestBackend.Cldr.Number.to_approx_string(12, locale: "nb", format: :roman)
  end

  test "en puts \"~\" before an accounting amount, whose negative pattern \"(¤#,##0.00)\" has no minus sign" do
    assert {:ok, "~$1,234.00"} ==
             TestBackend.Cldr.Number.to_approx_string(1234,
               locale: "en",
               currency: :USD,
               format: :accounting
             )
  end
end
