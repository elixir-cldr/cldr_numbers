number = "1234567.00"
locale = Cldr.Locale.new!("en", MyApp.Cldr)

parse = fn x ->
  case Integer.parse(x) do
    {integer, ""} -> integer
    _other -> case Float.parse(x) do
      {float, ""} -> float
      _other -> x
    end
  end
end

Benchee.run(
  %{
    "Cldr.Number.Parser.parse" => fn -> Cldr.Number.Parser.parse(number) end,
    "Cldr.Number.Parser.parse(locale)" => fn -> Cldr.Number.Parser.parse(number, locale: locale) end,
    "Float.parse" => fn -> Float.parse(number) end,
    "Flexi parser" => fn -> parse.(number) end
  },
  time: 10,
  memory_time: 2
)