defmodule Cldr.Number.Backend do
  @moduledoc false

  def define_number_modules(config) do
    alias Cldr.Number.Backend

    [
      Backend.Number.define_number_module(config),
      Backend.Format.define_number_module(config),
      Backend.Decimal.Formatter.define_number_module(config),
      Backend.Transliterate.define_number_module(config),
      Backend.System.define_number_module(config),
      Backend.Symbol.define_number_module(config),
      Backend.Rbnf.define_number_system_module(config),
      Backend.Rbnf.define_spellout_module(config),
      Backend.Rbnf.define_ordinal_module(config),
      Cldr.Currency.Backend.define_currency_module(config)
    ]
    |> Enum.map(fn
      {module_name, body, env} ->
        Task.async(fn ->
          case Module.create(module_name, body, env) do
            {:module, name, bytecode, _last_quoted} ->
              write_beam_file!(name, bytecode)
            other ->
              raise "Couldn't compile #{inspect module_name}: #{inspect other}"
          end
        end)
      :ok ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> Task.await_many(:infinity)
  end

  defp write_beam_file!(module_name, bytecode) do
    dir = Application.app_dir(:ex_cldr_numbers) <> "/ebin"
    path = Path.join(dir, "#{module_name}.beam")
    File.write!(path, bytecode)
  end
end
