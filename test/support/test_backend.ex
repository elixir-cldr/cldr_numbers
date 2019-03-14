defmodule TestBackend.Cldr do
  use Cldr,
    default_locale: "en",
    locales: :all,
    precompile_transliterations: [{:latn, :arab}, {:arab, :thai}, {:arab, :latn}],
    providers: [Cldr.Number]

end

defmodule NoDoc.Cldr do
  use Cldr,
    generate_docs: false

end
