defmodule CldrNumbersTest do
  use ExUnit.Case

  if function_exported?(Code, :fetch_docs, 1) do
    @modules [Number, Number.System, Number.Format, Number.Symbol,
      Number.Transliterate, Number.Formatter.Decimal, Rbnf.NumberSystem, Rbnf.Spellout, Rbnf.Ordinal]

    test "that no module docs are generated for a backend" do
      for mod <- @modules do
        module = Module.concat(NoDoc.Cldr, mod)
        assert {:docs_v1, _, :elixir, _, :hidden, %{}, _} = Code.fetch_docs(module)
      end
    end

    assert "that module docs are generated for a backend" do
      for mod <- @modules do
        module = Module.concat(TestBackend.Cldr, mod)
        {:docs_v1, 1, :elixir, "text/markdown", _, %{}, _} = Code.fetch_docs(module)
      end
    end
  end
end
