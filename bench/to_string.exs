{:ok, options} = Cldr.Number.Format.Options.validate_options([], MyApp.Cldr, locale: Cldr.get_locale())
number = 100000.55

Benchee.run(
  %{
    "Number to_string" => fn -> MyApp.Cldr.Number.to_string number end,
    "Number to_string preformatted options" => fn -> MyApp.Cldr.Number.to_string number, options end,
    "Float to_string" => fn -> Float.to_string number end,
    ":erlang.float_to_binary" => fn -> :erlang.float_to_binary(number, [:compact, decimals: 3]) end
  },
  time: 10,
  memory_time: 2
)