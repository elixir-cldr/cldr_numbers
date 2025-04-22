defmodule Number.Format.Test do
  use ExUnit.Case, async: true

  Enum.each(Cldr.Test.Number.Format.test_data(), fn {value, result, args} ->
    new_args =
      if args[:locale] do
        Keyword.put(args, :locale, TestBackend.Cldr.Locale.new!(Keyword.get(args, :locale)))
      else
        args
      end

    test "formatted #{inspect(value)} == #{inspect(result)} with args: #{inspect(args)}" do
      assert {:ok, unquote(result)} =
               TestBackend.Cldr.Number.to_string(unquote(value), unquote(Macro.escape(new_args)))
    end
  end)

  test "to_string with no arguments" do
    assert {:ok, "1,234"} = Cldr.Number.to_string(1234)
  end

  test "to_string with only options" do
    assert {:ok, "1.234"} = Cldr.Number.to_string(1234, locale: "de")
  end

  test "literal-only format returns the literal" do
    assert {:ok, "xxx"} = TestBackend.Cldr.Number.to_string(1234, format: "xxx")
  end

  test "formatted float with rounding" do
    assert {:ok, "1.40"} == TestBackend.Cldr.Number.to_string(1.4, fractional_digits: 2)
  end

  test "a currency format with no currency returns a currency formatted number" do
    assert {:ok, "1,234.00"} = TestBackend.Cldr.Number.to_string(1234, format: :currency)
  end

  test "that -0 is formatted as 0" do
    number = Decimal.new("-0")
    assert TestBackend.Cldr.Number.to_string(number) == {:ok, "0"}
  end

  test "minimum_grouping digits delegates to Cldr.Number.Symbol" do
    assert TestBackend.Cldr.Number.Format.minimum_grouping_digits_for!("en") == 1
  end

  test "that there are decimal formats for a locale" do
    assert Map.keys(TestBackend.Cldr.Number.Format.all_formats_for!("en")) == [:latn]
  end

  test "that there is an exception if we get formats for an unknown locale" do
    assert_raise Cldr.InvalidLanguageError, ~r/The language .* is invalid/, fn ->
      TestBackend.Cldr.Number.Format.formats_for!("zzz")
    end
  end

  test "that there is an exception if we get formats for an number system" do
    assert_raise Cldr.UnknownNumberSystemError, ~r/The number system \"zulu\" is invalid/, fn ->
      TestBackend.Cldr.Number.Format.formats_for!("en", "zulu")
    end
  end

  test "that an rbnf format request fails if the locale doesn't define the ruleset" do
    assert TestBackend.Cldr.Number.to_string(123, format: :spellout_ordinal_verbose, locale: "zh") ==
             {
               :error,
               {
                 Cldr.Rbnf.NoRule,
                 "RBNF rule :spellout_ordinal_verbose is unknown to locale TestBackend.Cldr.Locale.new!(\"zh-Hans-CN\")"
               }
             }
  end

  test "that we get default formats_for" do
    assert TestBackend.Cldr.Number.Format.formats_for!().__struct__ == Cldr.Number.Format
  end

  test "setting currency_format: :iso" do
    assert TestBackend.Cldr.Number.to_string(123, currency: :USD, currency_symbol: :iso) ==
             {:ok, "USD 123.00"}
  end

  test "round_nearest to_string parameter" do
    assert Cldr.Number.to_string(1234, MyApp.Cldr, round_nearest: 5) == {:ok, "1,235"}
    assert Cldr.Number.to_string(1231, MyApp.Cldr, round_nearest: 5) == {:ok, "1,230"}
    assert Cldr.Number.to_string(1234, MyApp.Cldr, round_nearest: 10) == {:ok, "1,230"}
    assert Cldr.Number.to_string(1231, MyApp.Cldr, round_nearest: 10) == {:ok, "1,230"}
    assert Cldr.Number.to_string(1235, MyApp.Cldr, round_nearest: 10) == {:ok, "1,240"}
  end

  test "fraction digits of 0" do
    assert Cldr.Number.to_string(50.12, MyApp.Cldr, fractional_digits: 0, currency: :USD) ==
             {:ok, "$50"}

    assert Cldr.Number.to_string(50.82, MyApp.Cldr, fractional_digits: 0, currency: :USD) ==
             {:ok, "$51"}
  end

  test "to_string with :percent format" do
    assert MyApp.Cldr.Number.to_string!(123.456, format: :percent, fractional_digits: 1) ==
             "12,345.6%"
  end

  test "negative decimal short formatting" do
    assert MyApp.Cldr.Number.to_string(Decimal.new(1_000_000), format: :short) == {:ok, "1M"}
    assert MyApp.Cldr.Number.to_string(Decimal.new(-1_000_000), format: :short) == {:ok, "-1M"}
    assert MyApp.Cldr.Number.to_string(Decimal.new(100_000), format: :short) == {:ok, "100K"}
    assert MyApp.Cldr.Number.to_string(Decimal.new(-100_000), format: :short) == {:ok, "-100K"}
    assert MyApp.Cldr.Number.to_string(Decimal.new(1_000), format: :short) == {:ok, "1K"}
    assert MyApp.Cldr.Number.to_string(Decimal.new(-1_000), format: :short) == {:ok, "-1K"}
  end

  test "Decimal currency short formatting" do
    assert MyApp.Cldr.Number.to_string(Decimal.new(1_000_000), format: :currency_short) ==
             {:ok, "$1M"}

    assert MyApp.Cldr.Number.to_string(Decimal.new(1_100_000),
             format: :currency_short,
             fractional_digits: 1
           ) == {:ok, "$1.1M"}

    assert MyApp.Cldr.Number.to_string(Decimal.new(1_000_000), format: :short) == {:ok, "1M"}

    assert MyApp.Cldr.Number.to_string(Decimal.new(1_100_000),
             format: :short,
             fractional_digits: 1
           ) == {:ok, "1.1M"}
  end

  test "Currency with :narrow formatting uses standard format with narrow symbol" do
    assert MyApp.Cldr.Number.to_string(Decimal.new(1_000_000), currency: :USD, format: :narrow) ==
             {:ok, "$1,000,000.00"}
  end

  test "Decimal currency short with fractional digits formatting" do
    assert Cldr.Number.to_string(Decimal.new("214564569.50"),
             format: :short,
             currency: :USD,
             fractional_digits: 2
           ) ==
             {:ok, "$214.56M"}

    assert Cldr.Number.to_string(Decimal.new("219.50"),
             format: :short,
             currency: :USD,
             fractional_digits: 2
           ) ==
             {:ok, "$219.50"}

    assert Cldr.Number.to_string(Decimal.from_float(219.50),
             format: :short,
             currency: :USD,
             fractional_digits: 2
           ) ==
             {:ok, "$219.50"}
  end

  test "Currency format long with symbol" do
    assert Cldr.Number.to_string(1_000_000_000, format: :currency_long_with_symbol, locale: "fr") ==
             {:ok, "1 milliard €"}

    assert Cldr.Number.to_string(1_000_000_000, format: :currency_long_with_symbol) ==
             {:ok, "$1 billion"}

    assert Cldr.Number.to_string(1_000_000_000, format: :currency_long_with_symbol, locale: "hr") ==
             {:ok, "1 milijardi €"}

    assert Cldr.Number.to_string(1_000_000_000,
             format: :currency_long_with_symbol,
             locale: "hr",
             currency: :USD
           ) ==
             {:ok, "1 milijardi USD"}

    assert Cldr.Number.to_string(1_234_545_656.456789,
             currency: "BTC",
             format: :currency_long_with_symbol
           ) ==
             {:ok, "₿1 billion"}
  end

  test "NaN and Inf decimal number formatting" do
    assert {:ok, "NaN"} = Cldr.Number.to_string(Decimal.new("NaN"))
    assert {:ok, "-NaN"} = Cldr.Number.to_string(Decimal.new("-NaN"))
    assert {:ok, "∞"} = Cldr.Number.to_string(Decimal.new("Inf"))
    assert {:ok, "-∞"} = Cldr.Number.to_string(Decimal.new("-Inf"))
    assert {:ok, "∞"} = Cldr.Number.to_string(Decimal.new("Inf"), locale: :de)
    assert {:ok, "-∞"} = Cldr.Number.to_string(Decimal.new("-Inf"), locale: :de)

    assert {:ok, "-∞"} =
             Cldr.Number.to_string(Decimal.new("-Inf"), format: "########", locale: :de)

    assert {:ok, "∞ and beyond"} =
             Cldr.Number.to_string(Decimal.new("Inf"), format: "# and beyond")
  end

  test "A free form currency format where the currency symbol is not first or last" do
    assert {:ok, "US$1,234"} =
             MyApp.Cldr.Number.to_string(1234, currency: "USD", format: "US¤#,###")
  end

  if System.otp_release() < "28" do
    test "Digital tokens with overriden symbols" do
      assert {:ok, "₿ 1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789,
                 currency: "BTC",
                 currency_symbol: :narrow
               )

      assert {:ok, "BTC 1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789, currency: "BTC", currency_symbol: :iso)

      assert {:ok, "₿ 1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789,
                 currency: "BTC",
                 currency_symbol: :symbol
               )

      assert {:ok, "₿ 1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789,
                 currency: "BTC",
                 currency_symbol: :standard
               )

      assert {:ok, "XBTC 1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789, currency: "BTC", currency_symbol: "XBTC")
    end
  else
    test "Digital tokens with overriden symbols" do
      assert {:ok, "₿1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789,
                 currency: "BTC",
                 currency_symbol: :narrow
               )

      assert {:ok, "BTC 1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789, currency: "BTC", currency_symbol: :iso)

      assert {:ok, "₿1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789,
                 currency: "BTC",
                 currency_symbol: :symbol
               )

      assert {:ok, "₿1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789,
                 currency: "BTC",
                 currency_symbol: :standard
               )

      assert {:ok, "XBTC 1,234,545,656.456789"} =
               Cldr.Number.to_string(1_234_545_656.456789, currency: "BTC", currency_symbol: "XBTC")
    end
  end

  test "Formatting a number with standard format in a locale with no RBNF" do
    for {_locale, language_tag} <- Cldr.Config.all_language_tags(),
        is_nil(language_tag.rbnf_locale_name) do
      assert {:ok, _formatted_number} = Cldr.Number.to_string(1234, locale: language_tag)
    end
  end

  test "that each number system for each locale can format a number with standard format" do
    for locale <- TestBackend.Cldr.known_locale_names() do
      {:ok, systems} = TestBackend.Cldr.Number.System.number_systems_for(locale)
      number_systems = Enum.uniq(Map.keys(systems) ++ Map.values(systems))

      for number_system <- number_systems do
        assert {:ok, _} =
                 TestBackend.Cldr.Number.to_string(123,
                   locale: locale,
                   number_system: number_system
                 )
      end
    end
  end

  test "Formatting when a currency is specified but the format has no currency symbol" do
    assert {:ok, _} =
             Cldr.Number.to_string(1234,
               curency: :CAD,
               format: "#,##0.###;-#,##0.###",
               locale: :en
             )
  end

  test "Formatting a currency the standard format if the it has a space before the currency placeholder" do
    assert {:ok, "123,45\u00A0kr."} =
      TestBackend.Cldr.Number.to_string(123.45, locale: :da, currency: :DKK)
  end
end
