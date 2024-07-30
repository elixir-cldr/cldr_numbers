defmodule Cldr.Number.ForDialyzer do
  @moduledoc """
  Includes functions intended only to give dialyzer some
  opportunity to check specs.

  """

  def for_dialyzer do
    formats = MyApp.Cldr.Number.Format.all_formats_for!(:en)
    formats
  end
end