defmodule Cldr.Number.Backend do
  def define_number_modules(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      unquote Cldr.Number.Backend.Number.define_number_module(config)
      unquote Cldr.Number.Backend.Transliterate.define_number_module(config)
      unquote Cldr.Number.Backend.Symbol.define_number_module(config)
      unquote Cldr.Number.Backend.Decimal.Formatter.define_number_module(config)
      unquote Cldr.Number.Backend.Format.define_number_module(config)
    end
  end
end