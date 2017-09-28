defmodule Cldr.Rbnf.NoRuleForNumber do
  @moduledoc """
  Exception raised when an attempt is made to invoke an RBNF rule for a number
  that is not supported by that rule.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end