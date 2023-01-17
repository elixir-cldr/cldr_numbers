defmodule NumberWrapper do
  def wrapper(string, tag) do
    "<#{tag}>" <> string <> "<#{tag}>"
  end
end