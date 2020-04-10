{:ok, options} = Cldr.Number.Format.Options.validate_options([], MyApp.Cldr, locale: Cldr.get_locale())

Benchee.run(
  %{
    "Number to_string" => fn -> MyApp.Cldr.Number.to_string 10000.55 end,
    "Number to_string preformatted options" => fn -> MyApp.Cldr.Number.to_string 10000.55, options end,
    "Float to_string" => fn -> Float.to_string 10000.55 end
  },
  time: 10,
  memory_time: 2
)