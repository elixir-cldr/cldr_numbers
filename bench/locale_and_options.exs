Benchee.run(
  %{
    "Cldr.locale_and_backend_from" => fn -> Cldr.locale_and_backend_from([]) end
    },
  time: 10,
  memory_time: 2
)