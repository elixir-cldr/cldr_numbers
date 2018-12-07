defmodule Cldr.FunctionClause do
  @moduledoc """
  Format function clauses using Exception.blame/3

  """

  @doc """
  Given a `module`, `function`, and `args` see
  that function clause would match or not match.

  This is useful for helping diagnose function
  clause errors when many clauses are generated
  at compile time.

  """
  @spec match(module(), atom(), [any(), ...]) :: binary()
  def match(module, function, args) when is_list(args) do
    case Exception.blame_mfa(module, function, args) do
      {:ok, kind, clauses} -> formatted_clauses(function, kind, clauses, &blame_match/2)
      _error -> "No known function clauses match #{inspect module}.#{function}/#{length(args)}"
    end
  end

  defp formatted_clauses(function, kind, clauses, ast_fun) do
    format_clause_fun = fn {args, guards} ->
      code = Enum.reduce(guards, {function, [], args}, &{:when, [], [&2, &1]})
      "    #{kind} " <> Macro.to_string(code, ast_fun) <> "\n"
    end

    clauses
    |> Enum.map(format_clause_fun)
    |> Enum.join()
    |> IO.puts
  end

  defp blame_match(%{match?: true, node: node}, _),
    do: Macro.to_string(node)
  defp blame_match(%{match?: false, node: node}, _),
    do: IO.ANSI.red() <> Macro.to_string(node) <> IO.ANSI.reset()
  defp blame_match(_, string), do: string

end
