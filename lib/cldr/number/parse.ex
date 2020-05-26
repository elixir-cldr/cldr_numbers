defmodule Cldr.Number.Parser do
  @moduledoc """
  Parse a string into a number and possibly a currency code

  """
  def parse(string, options \\ []) do


  end

  defp parse_number(string, locale, backend) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend),
         {:ok, symbols} <- Cldr.Number.Symbol.number_symbols_for(locale, backend) do
      decimal =
        string
        |> String.replace(symbols.latn.group, "")
        |> String.replace(symbols.latn.decimal, ".")
        |> Decimal.new()

      {:ok, decimal}
    end
  end

end