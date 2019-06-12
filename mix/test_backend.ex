require Cldr.Number.Backend

defmodule MyApp.Cldr do
  @moduledoc false

  use Cldr,
    default_locale: "en",
    locales: ["en", "zh", "zh-Hant", "it", "fr", "de", "th", "id", "ru", "he", "pl"],
    precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}],
    providers: [Cldr.Number]
end

defmodule MyApp.Cldr2 do
  @moduledoc false

  use Cldr,
    default_locale: "en-GB",
    locales: ["en-GB", "hu"],
    precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}],
    providers: [Cldr.Number]
end
