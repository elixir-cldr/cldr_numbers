defmodule Cldr.Rbnf.Compiler.Test do
  use ExUnit.Case, async: true

  test "that rbnf rules can parse" do
    Enum.each(Cldr.Rbnf.all_rule_definitions(TestBackend.Cldr), fn rule ->
      parse_result = Cldr.Rbnf.Rule.parse(rule)
      assert [{:ok, _}, _] = [parse_result, rule]
    end)
  end
end
