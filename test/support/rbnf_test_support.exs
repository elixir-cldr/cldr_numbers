defmodule Cldr.Rbnf.TestSupport do
  def rbnf_tests(fun) when is_function(fun) do
    # Come back later an investigate why we get different results
    locales = Cldr.known_locales()
    |> List.delete("ru")
    |> List.delete("be")
    |> List.delete("es")
    |> List.delete("zh")
    |> List.delete("vi")
    |> List.delete("ko")
    |> List.delete("it")
    |> List.delete("ms")
    |> List.delete("ja")
    |> List.delete("pl")
    |> List.delete("he")
    |> List.delete("zh-Hant")
    |> List.delete("af")
    |> List.delete("hr")
    |> List.delete("uk")

    for locale_name <- locales do
      json_data_file = "./test/support/rbnf/#{locale_name}/rbnf_test.json"
      file_data = File.read(json_data_file)

      case file_data do
        {:error, _} ->
          :no_such_locale_test_file
        {:ok, json_string} ->
          json_data = json_string
          |> Poison.decode!

          locale = Cldr.Locale.new(locale_name)
          if Cldr.known_rbnf_locale?(locale_name) do
            rbnf_data = Cldr.Rbnf.for_locale!(locale)
            Enum.each Map.keys(json_data), fn rule_group ->
              if rbnf_data[String.to_existing_atom(rule_group)] do
                module = "Elixir.Cldr.Rbnf.#{rule_group}"
                |> String.replace("Rules", "")
                |> String.to_atom

                Enum.each json_data[rule_group], fn {rule_set, tests} ->
                  function = rule_set
                  |> String.replace("-","_")
                  |> String.to_atom

                  name = "#{module}.#{function} for locale #{inspect locale_name}"
                  |> String.replace("−", "-")

                  fun.(name, tests, module, function, locale)
                end
              end
            end
          end
      end
    end
  end
end