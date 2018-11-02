defmodule Cldr.Number.Backend do
  def define_number_modules(config) do
    quote location: :keep do
      unquote Cldr.Number.Backend.Number.define_number_module(config)
      unquote Cldr.Number.Backend.Format.define_number_module(config)
      # unquote Cldr.Number.Backend.Transliterate.define_number_module(config)
      unquote Cldr.Number.Backend.Symbol.define_number_module(config)
      unquote Cldr.Number.Backend.Decimal.Formatter.define_number_module(config)
      unquote Cldr.Number.Backend.Rbnf.define_number_modules(config)
    end
  end
end