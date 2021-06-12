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

defmodule Cldr.Rbnf.NoRule do
  @moduledoc """
  Exception raised when an attempt is made to invoke an RBNF rule that
  is not supported for a given locale
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.CurrencyAlreadyDefined do
  @moduledoc """
  Exception raised when an attempt is made to define a currency
  that already exists.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.CurrencyCodeInvalid do
  @moduledoc """
  Exception raised when an attempt is made to define a currency
  code that is invalid.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.NoNumberSymbols do
  @moduledoc """
  Exception raised when when there are no number
  symbols for a locale and number system.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Cldr.Number.ParseError do
  @moduledoc """
  Exception raised when when trying to parse
  a string into a number and the string is
  not parseable.
  """
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end