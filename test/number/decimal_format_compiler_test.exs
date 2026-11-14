defmodule DecimalFormatCompiler.Test do
  use ExUnit.Case, async: true

  alias Cldr.Number.Format

  Enum.each(TestBackend.Cldr.Number.Format.decimal_format_list(), fn format ->
    test "Compile decimal format #{inspect(format)}" do
      assert {:ok, _result} = Format.Compiler.parse(unquote(format))
    end
  end)

  test "compile fails on empty format" do
    assert {:error, _result} = Format.Compiler.parse("")
  end

  test "compile fails on nil format" do
    assert {:error, _result} = Format.Compiler.parse(nil)
  end

  test "that we can parse a token list" do
    {:ok, tokens, _} = Format.Compiler.tokenize("#")
    assert {:ok, _parse_tree} = Format.Compiler.parse(tokens)
  end

  # A quoted literal of more than one character, and a quote that is never
  # closed, used to send the lexer into an endless loop.
  test "a quoted literal of more than one character is a literal" do
    assert {:ok,
            [positive: [literal: "abc ", format: "0.0", literal: " def"], negative: _negative]} =
             Format.Compiler.parse("'abc' 0.0 'def'")

    assert {:ok, [positive: [literal: "abc", format: "0"], negative: _negative]} =
             Format.Compiler.parse("'abc'0")

    assert {:ok, [positive: [format: "0.0", literal: " def"], negative: _negative]} =
             Format.Compiler.parse("0.0 'def'")
  end

  test "pattern characters and doubled quotes inside a quoted literal are text" do
    assert {:ok, "#,##0 1234.5"} ==
             TestBackend.Cldr.Number.to_string(1234.5, format: "'#,##0' 0.0")

    assert {:ok, "1234 o'clock"} ==
             TestBackend.Cldr.Number.to_string(1234, format: "0 'o''clock'")

    assert {:ok, "'1234"} == TestBackend.Cldr.Number.to_string(1234, format: "''''0")
    assert {:ok, "a 1234 b"} == TestBackend.Cldr.Number.to_string(1234, format: "'a' 0 'b'")
  end

  test "an unterminated quote is an error" do
    for format <- ["'abc", "0 'abc", "'", "0'", "'0"] do
      assert {:error, "Decimal format compiler: illegal characters" <> _rest} =
               Format.Compiler.parse(format)

      assert {:error, "Decimal format compiler: illegal characters" <> _rest} =
               Format.Compiler.format_to_metadata(format)

      assert {:error, "Decimal format compiler: illegal characters" <> _rest} =
               Format.Compiler.compile(format)

      assert {:error, {Cldr.FormatCompileError, _message}} =
               TestBackend.Cldr.Number.to_string(1234, format: format)
    end
  end

  test "a run of more than four currency signs is an error" do
    for count <- [5, 50] do
      format = String.duplicate("¤", count) <> "0"

      assert {:error, "Decimal format compiler: a currency symbol is one to four currency signs"} ==
               Format.Compiler.parse(format)
    end

    assert {:ok, [positive: [currency: 4, format: "0"], negative: _negative]} =
             Format.Compiler.parse("¤¤¤¤0")
  end

  test "a format that cannot be compiled is an error when a currency is given" do
    for format <- ["0.0.0", "'abc", "¤¤¤¤¤0"] do
      options = [format: format, currency: :USD]

      assert {:error, {Cldr.FormatCompileError, _message}} =
               TestBackend.Cldr.Number.to_string(1234, options)

      assert {:error, {Cldr.FormatCompileError, _message}} =
               Cldr.Number.Format.Options.validate_options(1234, TestBackend.Cldr, options)
    end

    assert {:ok, "Total: $1,234.00"} ==
             TestBackend.Cldr.Number.to_string(1234, format: "'Total:' ¤#,##0.00", currency: :USD)
  end
end
