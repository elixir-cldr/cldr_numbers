defmodule Mix.Tasks.Cldr.Number.GenerateRbnfTestData do
  @moduledoc """
  Generates RBNF test data
  """

  use Mix.Task
  require Logger

  @shortdoc "Generate RBNF test data"

  @output_directory "test/support/rbnf"

  # Check out possible bug being surfaced in PL
  @locales [
    :af, :be, :bg, :ca, :es, :gu, :he, :hi, :hr, :hu, :it, :ja, :ko, :ms, :pl, :ru,
    :uk, :vi, :zh, :"zh-Hant"
  ]

  @doc false
  def run(_) do
    for locale <- @locales do
      IO.puts "Generating RBNF test data for locale #{locale}"

      tests =
        "#{@output_directory}/#{locale}/rbnf_test.json"
        |> File.read!()
        |> Jason.decode!()
        |> Enum.map(fn {rule_group, rule_examples} -> {rule_group, generate_tests(locale, rule_examples)} end)
        |> Map.new()
        |> Jason.encode!(pretty: true)

      File.write("#{@output_directory}/#{locale}/rbnf_test_2.json", tests)
    end
  end

  defp generate_tests(locale, rule_examples) do
    Enum.map(rule_examples, fn {rule_string, examples} ->
      rule =
        rule_string
        |> String.replace("-", "_")
        |> String.to_atom()

      IO.puts "Building examples for rule #{rule} in locale #{locale}"

      examples =
        Enum.map(examples, fn {number, _result} ->
          int = String.to_integer(number)
          {:ok, result} = Cldr.Number.to_string int, format: rule, locale: locale, backend: TestBackend.Cldr
          {number, result}
        end)
        |> Map.new()

      {rule_string, examples}
    end)
    |> Map.new()
  end
end