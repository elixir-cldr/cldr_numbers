Benchee.run(
  %{
    "keyword options" => fn -> MyApp.Cldr.Number.to_string 10000 end,
  },
  time: 10,
  memory_time: 2
)