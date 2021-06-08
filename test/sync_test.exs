defmodule Cldr.SyncTest do
  use ExUnit.Case

  test "that we raise if no default backend" do
    :ok = Application.delete_env(:ex_cldr, :default_backend)
    assert_raise Cldr.NoDefaultBackendError, fn ->
      Cldr.Number.to_string(1234)
    end
    :ok = Application.put_env(:ex_cldr, :default_backend, TestBackend.Cldr)
  end

end