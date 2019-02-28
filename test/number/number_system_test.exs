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
end
