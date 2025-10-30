defmodule Cldr.Rbnf.TestSupport do
  @test_data_needs_correcting [:ro, :pl]

  def rbnf_tests(fun) when is_function(fun) do
    locales = TestBackend.Cldr.known_locale_names()

    _force_atom_instantiation =  [OrdinalRules, CardinalRules]

    for locale_name <- locales,
        locale_name not in @test_data_needs_correcting do
      json_data_file = "./test/support/rbnf/#{locale_name}/rbnf_test.json"
      file_data = File.read(json_data_file)

      case file_data do
        {:error, _} ->
          :no_such_locale_test_file

        {:ok, json_string} ->
          json_data =
            json_string
            |> Jason.decode!()

          locale = TestBackend.Cldr.Locale.new!(locale_name)

          if Cldr.known_rbnf_locale_name?(locale_name, TestBackend.Cldr) do
            rbnf_data = Cldr.Rbnf.for_locale!(locale)

            Enum.each(Map.keys(json_data), fn rule_group ->
              if rbnf_data[String.to_existing_atom(rule_group)] do
                module =
                  "Elixir.TestBackend.Cldr.Rbnf.#{rule_group}"
                  |> String.replace("Rules", "")
                  |> String.to_atom()

                Enum.each(json_data[rule_group], fn {rule_set, tests} ->
                  function =
                    rule_set
                    |> String.replace("-", "_")
                    |> String.to_atom()

                  name =
                    "#{module}.#{function} for locale #{inspect(locale_name)}"
                    |> String.replace("_", "-")

                  fun.(name, tests, module, function, locale)
                end)
              end
            end)
          end
      end
    end
  end
end
