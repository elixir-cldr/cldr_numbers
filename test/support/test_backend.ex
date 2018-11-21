defmodule TestBackend.Cldr do
  use Cldr,
    default_locale: "en",
    locales: :all,
    precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}]
end
