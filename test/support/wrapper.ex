defmodule NumberWrapper do
  def wrapper(string, type) do
    {:ok, "<#{type}>" <> string <> "<#{type}>"}
  end
end