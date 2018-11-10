defmodule Cldr.Clause do
  @moduledoc false

  def functions(module, function, args) do
    {:ok, kind, clauses} = Exception.blame_mfa(module, function, args)
    formatted_clauses(function, kind, clauses, &blame_match/2)
  end

  def formatted_clauses(function, kind, clauses, ast_fun) do
    format_clause_fun = fn {args, guards} ->
      code = Enum.reduce(guards, {function, [], args}, &{:when, [], [&2, &1]})
      "    #{kind} " <> Macro.to_string(code, ast_fun) <> "\n"
    end

    clauses
    |> Enum.map(format_clause_fun)
    |> Enum.join()
  end

  defp blame_match(%{match?: true, node: node}, _), do: Macro.to_string(node)
  defp blame_match(%{match?: false, node: node}, _), do: "-" <> Macro.to_string(node) <> "-"
  defp blame_match(_, string), do: string
end
