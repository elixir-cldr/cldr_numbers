defmodule Cldr.Number.Parsing.Test do
  use ExUnit.Case, async: true

  test "parse numbers" do
    assert Cldr.Number.Parser.parse("100", backend: TestBackend.Cldr) == {:ok, 100}
    assert Cldr.Number.Parser.parse("100.0", backend: TestBackend.Cldr) == {:ok, 100.0}
    assert Cldr.Number.Parser.parse("1_000", backend: TestBackend.Cldr) == {:ok, 1000}
    assert Cldr.Number.Parser.parse("+1_000.0", backend: TestBackend.Cldr) == {:ok, 1000.0}
    assert Cldr.Number.Parser.parse("-100", backend: TestBackend.Cldr) == {:ok, -100}
    assert Cldr.Number.Parser.parse(" 100 ", backend: TestBackend.Cldr) == {:ok, 100}
  end

  test "parse numbers with locale other than en" do
    assert Cldr.Number.Parser.parse("1.000,00", backend: TestBackend.Cldr, locale: "de") ==
      {:ok, 1000.0}
  end

  test "scan a number string" do
    assert Cldr.Number.Parser.scan("100 australian dollars", backend: TestBackend.Cldr) ==
      [100, " australian dollars"]

    assert Cldr.Number.Parser.scan("us dollars 100", backend: TestBackend.Cldr) ==
      ["us dollars ", 100]
  end

  test "resolving currency and value" do
     result =
       Cldr.Number.Parser.scan("us dollars 100", backend: TestBackend.Cldr)
       |> Cldr.Number.Parser.resolve_currencies(backend: TestBackend.Cldr)

      assert result == [:USD, 100]

    result2 =
      Cldr.Number.Parser.scan("$100", backend: TestBackend.Cldr)
      |> Cldr.Number.Parser.resolve_currencies(backend: TestBackend.Cldr)

    assert result2 == [:USD, 100]
  end

end