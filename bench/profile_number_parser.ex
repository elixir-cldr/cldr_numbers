defmodule ProfileRunner do
  import ExProf.Macro

  @doc "analyze with profile macro"
  def do_analyze do
    profile do
      Cldr.Number.Parser.parse("1234.00")
    end
  end

  @doc "get analysis records and sum them up"
  def run do
    {records, _block_result} = do_analyze()

    records
    |> Enum.filter(&String.contains?(&1.function, "Cldr.Number.Parser"))
    |> ExProf.Analyzer.print
  end

end

ProfileRunner.run
