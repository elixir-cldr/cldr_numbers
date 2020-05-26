defmodule Cldr.Number.Doc.Test do
  use ExUnit.Case, async: true

  Application.put_env(:ex_cldr, :default_backend, TestBackend.Cldr)

  doctest Cldr.Number
  doctest Cldr.Number.String
  doctest Cldr.Number.Format
  doctest Cldr.Number.Symbol
  doctest Cldr.Number.System
  doctest Cldr.Number.Transliterate
  doctest Cldr.Number.Format.Compiler
  doctest Cldr.Number.Parser

  doctest Cldr.Number.Formatter.Decimal
  doctest Cldr.Number.Formatter.Short
  doctest Cldr.Number.Formatter.Currency

  doctest TestBackend.Cldr.Number.System
  doctest TestBackend.Cldr.Number
  doctest TestBackend.Cldr.Number.Symbol
  doctest TestBackend.Cldr.Number.Format
  doctest TestBackend.Cldr.Number.Transliterate

  doctest TestBackend.Cldr.Rbnf.Ordinal
  doctest TestBackend.Cldr.Rbnf.Spellout
  doctest TestBackend.Cldr.Rbnf.NumberSystem
end
