defmodule Cldr.Number.Exponent.Test do
  use ExUnit.Case, async: true

  test "An integer number exponent format with precision" do
    assert {:ok, "1.2E3"} = MyApp.Cldr.Number.to_string 1234, format: "0.0E0"
    assert {:ok, "1.23E3"} = MyApp.Cldr.Number.to_string 1234, format: "0.00E0"
    assert {:ok, "1.234E3"} = MyApp.Cldr.Number.to_string 1234, format: "0.000E0"
  end

  test "A float number exponent format with precision" do
    assert {:ok, "1.2E3"} = MyApp.Cldr.Number.to_string 1234.5678, format: "0.0E0"
    assert {:ok, "1.23E3"} = MyApp.Cldr.Number.to_string 1234.5678, format: "0.00E0"
    assert {:ok, "1.235E3"} = MyApp.Cldr.Number.to_string 1234.5678, format: "0.000E0"
    assert {:ok, "1.23457E3"} =  MyApp.Cldr.Number.to_string 1234.5678, format: "0.00000E0"
  end

  test "A Decimal number exponent format with precision" do
    assert {:ok, "1.2E3"} = MyApp.Cldr.Number.to_string Decimal.new("1234.5678"), format: "0.0E0"
    assert {:ok, "1.23E3"} = MyApp.Cldr.Number.to_string Decimal.new("1234.5678"), format: "0.00E0"
    assert {:ok, "1.235E3"} = MyApp.Cldr.Number.to_string Decimal.new("1234.5678"), format: "0.000E0"
    assert {:ok, "1.23457E3"} =  MyApp.Cldr.Number.to_string Decimal.new("1234.5678"), format: "0.00000E0"
  end

  test "An integer number exponent format with exponent precision" do
    assert {:ok, "1.2E03"} = MyApp.Cldr.Number.to_string 1234, format: "0.0E00"
    assert {:ok, "1.23E003"} = MyApp.Cldr.Number.to_string 1234, format: "0.00E000"
    assert {:ok, "1.234E0003"} = MyApp.Cldr.Number.to_string 1234, format: "0.000E0000"
  end

end