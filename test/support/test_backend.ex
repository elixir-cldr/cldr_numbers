defmodule TestBackend.Cldr do
  use Cldr,
    default_locale: "en",
    locales: :all,
    precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}],
    providers: [Cldr.Number],
    suppress_warnings: true
end

defmodule NoDoc.Cldr do
  use Cldr,
    generate_docs: false,
    suppress_warnings: true,
    default_currency_format: nil
end

defmodule DefaultCurrencyFormat do
  use Cldr,
    default_locale: "en",
    locales: ["en", "fr"],
    providers: [Cldr.Number],
    default_currency_format: :currency
end

defmodule DefaultAccountingFormat do
  use Cldr,
    default_locale: "en",
    locales: ["en", "fr"],
    providers: [Cldr.Number],
    default_currency_format: :accounting
end
