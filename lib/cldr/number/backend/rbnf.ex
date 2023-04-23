defmodule Cldr.Number.Backend.Rbnf do
  @moduledoc false

  def define_number_modules(config) do
    backend = config.backend
    root_locale = Cldr.Config.root_locale_name()

    quote location: :keep do
      defmodule Rbnf.NumberSystem do
        @moduledoc false
        if Cldr.Config.include_module_docs?(unquote(config.generate_docs)) do
          @moduledoc """
          Functions to implement the number system rule-based-number-format rules of CLDR.

          These rules are defined only on the "und" locale and represent specialised
          number formatting.

          The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

          The functions on this module are defined at compile time based upon the RBNF rules
          defined in the Unicode CLDR data repository.  Available rules are identified by:

              iex> #{inspect(__MODULE__)}.rule_sets(#{inspect(unquote(root_locale))})
              ...> |> Enum.sort()
              [
                :armenian_lower,
                :armenian_upper,
                :cyrillic_lower,
                :ethiopic,
                :georgian,
                :greek_lower,
                :greek_upper,
                :hebrew,
                :hebrew_item,
                :roman_lower,
                :roman_upper,
                :tamil,
                :zz_default
              ]

          A rule can then be invoked on an available rule_set.  For example

              iex> #{inspect(__MODULE__)}.roman_upper(123, #{inspect(unquote(root_locale))})
              "CXXIII"

          This particular call is equivalent to the call through the public API of:

              iex> #{inspect(unquote(backend))}.Number.to_string(123, format: :roman)
              {:ok, "CXXIII"}

          """
        end

        import Kernel, except: [and: 2]
        use Cldr.Rbnf.Processor, backend: unquote(backend)

        define_rules(:NumberingSystemRules, unquote(backend), __ENV__)
      end

      defmodule Rbnf.Spellout do
        @moduledoc false
        if Cldr.Config.include_module_docs?(unquote(config.generate_docs)) do
          @moduledoc """
          Functions to implement the spellout rule-based-number-format rules of CLDR.

          As CLDR notes, the data is incomplete or non-existent for many languages.  It
          is considered complete for English however.

          The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

          The functions on this module are defined at compile time based upon the RBNF rules
          defined in the Unicode CLDR data repository.  Available rules are identified by:

              iex> #{inspect(__MODULE__)}.rule_sets("en")
              ...> |> Enum.sort()
              [
                :spellout_cardinal,
                :spellout_cardinal_verbose,
                :spellout_numbering,
                :spellout_numbering_verbose,
                :spellout_numbering_year,
                :spellout_ordinal,
                :spellout_ordinal_verbose
              ]

          A rule can then be invoked on an available rule_set. For example:

              iex> #{inspect(__MODULE__)}.spellout_ordinal(123, "en")
              "one hundred twenty-third"

          This call is equivalent to the call through the public API of:

              iex> #{inspect(unquote(backend))}.Number.to_string(123, format: :spellout)
              {:ok, "one hundred twenty-three"}

          """
        end

        import Kernel, except: [and: 2]
        use Cldr.Rbnf.Processor, backend: unquote(backend)

        define_rules(:SpelloutRules, unquote(backend), __ENV__)
      end

      defmodule Rbnf.Ordinal do
        @moduledoc false
        if Cldr.Config.include_module_docs?(unquote(config.generate_docs)) do
          @moduledoc """
          Functions to implement the ordinal rule-based-number-format rules of CLDR.

          As CLDR notes, the data is incomplete or non-existent for many languages.  It
          is considered complete for English however.

          The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

          The functions on this module are defined at compile time based upon the RBNF rules
          defined in the Unicode CLDR data repository.  Available rules are identified by:

              iex> #{inspect(__MODULE__)}.rule_sets(:en)
              [:digits_ordinal]

              iex> #{inspect(__MODULE__)}.rule_sets("fr")
              ...> |> Enum.sort()
              [
                :digits_ordinal,
                :digits_ordinal_feminine,
                :digits_ordinal_feminine_plural,
                :digits_ordinal_masculine,
                :digits_ordinal_masculine_plural
              ]

          A rule can then be invoked on an available rule_set.  For example

              iex> #{inspect(__MODULE__)}.digits_ordinal(123, :en)
              "123rd"

          This call is equivalent to the call through the public API of:

              iex> #{inspect(unquote(backend))}.Number.to_string(123, format: :ordinal)
              {:ok, "123rd"}

          """
        end

        import Kernel, except: [and: 2]
        use Cldr.Rbnf.Processor, backend: unquote(backend)

        define_rules(:OrdinalRules, unquote(backend), __ENV__)
      end
    end
  end
end
