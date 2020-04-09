defimpl Cldr.Chars, for: [Float, Integer, Decimal] do
  def to_string(number) do
    locale = Cldr.get_locale()
    Cldr.Number.to_string!(number, locale.backend, locale: locale)
  end
end
