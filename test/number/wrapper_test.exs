defmodule Number.FormatWrapper.Test do
  use ExUnit.Case, async: true

  test "Wrapping a number" do
    assert {:ok, "<number>100<number>"} =
      Cldr.Number.to_string(100, wrapper: &NumberWrapper.wrapper/2)
  end

  test "Wrapping a currency symbol" do
    assert {:ok, "<currency_symbol>$<currency_symbol><number>100.00<number>"} =
      Cldr.Number.to_string(100, currency: :USD, wrapper: &NumberWrapper.wrapper/2)
  end

  test "Wrapping a currency symbol with inserted space" do
    assert {:ok, "<currency_symbol>CHF<currency_symbol><currency_space> <currency_space><number>100.00<number>"} =
      Cldr.Number.to_string(100, currency: :CHF, wrapper: &NumberWrapper.wrapper/2)
  end

  test "Wrapping a percent and permille" do
    assert {:ok, "<number>10,000<number><percent>%<percent>"} =
      Cldr.Number.to_string(100, format: :percent, wrapper: &NumberWrapper.wrapper/2)
  end

  test "Wrapping plus and minus" do
    assert {:ok, "<plus>+<plus><number>100<number>"} =
      Cldr.Number.to_string(100, format: "+##", wrapper: &NumberWrapper.wrapper/2)

    assert {:ok, "<minus>-<minus><number>100<number>"} =
      Cldr.Number.to_string(-100, format: "##", wrapper: &NumberWrapper.wrapper/2)
  end
end