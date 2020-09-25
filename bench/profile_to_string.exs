defmodule ProfileRunner do
  import ExProf.Macro

  @doc "analyze with profile macro"
  def do_analyze do
    {:ok, options} = Cldr.Number.Format.Options.validate_options(0, MyApp.Cldr, [])
    profile do
      MyApp.Cldr.Number.to_string 1234, options
    end
  end

  @doc "get analysis records and sum them up"
  def run do
    {records, _block_result} = do_analyze()

    records
    |> Enum.filter(&String.contains?(&1.function, "Cldr.Number"))
    |> ExProf.Analyzer.print
  end

end

ProfileRunner.run

#
# Total:                                                                             215  100.00%   328  [      1.53]
# %Prof{
#   calls: 1,
#   function: "'Elixir.Cldr.Number.Formatter.Decimal':add_first_group/3",
#   percent: 0.0,
#   time: 0,
#   us_per_call: 0.0
# }