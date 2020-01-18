defmodule Number.System.Test do
  use ExUnit.Case, async: true

  test "that number_system_for with a system name returns" do
    {:ok, system} = TestBackend.Cldr.Number.System.number_system_for("en", :latn)
    assert system == %{digits: "0123456789", type: :numeric}
  end

  test "that number_systems_for raises when the locale is not known" do
    assert_raise Cldr.UnknownLocaleError, ~r/The locale \"zzz\" is not known/, fn ->
      TestBackend.Cldr.Number.System.number_systems_for!("zzz")
    end
  end

  test "that number_system_names_for raises when the locale is not known" do
    assert_raise Cldr.UnknownLocaleError, ~r/The locale .* is not known/, fn ->
      TestBackend.Cldr.Number.System.number_system_names_for!("zzz")
    end
  end

  test "that number_systems_like returns a list" do
    {:ok, likes} = Cldr.Number.System.number_systems_like("en", :latn, TestBackend.Cldr)
    assert is_list(likes)
    assert Enum.count(likes) > 100
  end

  test "that locale u extension number system overrides default" do
    assert TestBackend.Cldr.Number.to_string(1234, locale: "th-u-nu-thai") == {:ok, "๑,๒๓๔"}
    assert TestBackend.Cldr.Number.to_string(1234, locale: "th-u-nu-latn") == {:ok, "1,234"}
  end

  test "that number_system parameter overrides the locale u number system" do
    assert TestBackend.Cldr.Number.to_string(1234, locale: "th-u-nu-latn", number_system: :thai) ==
      {:ok, "๑,๒๓๔"}
  end

  test "that a locale u number system that is not valid for a locale returns an error" do
    assert TestBackend.Cldr.Number.to_string(1234, locale: "en-AU-u-nu-thai") ==
    {:error,
     {Cldr.UnknownNumberSystemError,
      "The number system :thai is unknown for the locale named \"en-AU\". Valid number systems are %{default: :latn, native: :latn}"}}
  end

end
