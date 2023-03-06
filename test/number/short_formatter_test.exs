defmodule Cldr.Number.ShortFormatter.Test do
  use ExUnit.Case, async: true

  test "Short formatter for a decimal" do
    number = Decimal.new("940038.00000000")
    assert {:ok, "940K"} =  MyApp.Cldr.Number.to_string(number, format: :short)
  end
end