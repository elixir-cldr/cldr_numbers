require Cldr.Number.Backend

defmodule MyApp.Cldr do
  @moduledoc false

  use Cldr,
    default_locale: "en",
    locales: [
      "en",
      "bn",
      "zh",
      "zh-Hant",
      "it",
      "de",
      "th",
      "id",
      "ru",
      "he",
      "pl",
      "es",
      "hr",
      "nb",
      "no",
      "en-IN",
      "ur",
      "fr-CH",
      "fr-BE",
      "ta",
      "he",
      "pt-CV",
      "ar-EG",
      "en-ZA"
    ],
    precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}],
    providers: [Cldr.Number],
    suppress_warnings: true
end

defmodule MyApp.Cldr2 do
  @moduledoc false

  use Cldr,
    default_locale: "en-GB",
    locales: ["en-GB", "hu", "ar", "de"],
    precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}, {:thai, :latn}],
    providers: [Cldr.Number],
    suppress_warnings: true
end
