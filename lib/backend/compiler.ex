defmodule Cldr.Number.Backend do
  @moduledoc false

  def define_number_modules(config) do
    quote location: :keep do
      unquote(Cldr.Number.Backend.Number.define_number_module(config))
      unquote(Cldr.Number.Backend.Format.define_number_module(config))
      unquote(Cldr.Number.Backend.Transliterate.define_number_module(config))
      unquote(Cldr.Number.Backend.System.define_number_module(config))
      unquote(Cldr.Number.Backend.Symbol.define_number_module(config))
      unquote(Cldr.Number.Backend.Decimal.Formatter.define_number_module(config))
      unquote(Cldr.Number.Backend.Rbnf.define_number_modules(config))

      # Number requires Currency
      unquote(Cldr.Currency.Backend.define_currency_module(config))
    end
  end
end
