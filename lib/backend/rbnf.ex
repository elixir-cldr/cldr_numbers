defmodule Cldr.Number.Backend.Rbnf do
  def define_number_modules(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Number.Rbnf.NumberSystem do
        @moduledoc """
        Functions to implement the number system rule-based-number-format rules of CLDR.

        These rules are defined only on the "root" locale and represent specialised
        number formatting.

        The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

        The functions on this module are defined at compile time based upon the RBNF rules
        defined in the Unicode CLDR data repository.  Available rules are identified by:

            iex> Cldr.Rbnf.NumberSystem.rule_sets Cldr.Locale.new!("root")
            [:tamil, :roman_upper, :roman_lower, :hebrew_item, :hebrew_0_99, :hebrew,
            :greek_upper, :greek_lower, :georgian, :ethiopic_p1, :ethiopic,
            :cyrillic_lower_1_10, :cyrillic_lower, :armenian_upper, :armenian_lower]

        A rule can then be invoked on an available rule_set.  For example

            iex> Cldr.Rbnf.NumberSystem.roman_upper 123, Cldr.Locale.new!("root")
            "CXXIII"

        This call is equivalent to the call through the public API of:

            iex> Cldr.Number.to_string 123, format: :roman
            {:ok, "CXXIII"}

        """

        import Kernel, except: [and: 2]
        use Cldr.Rbnf.Processor, backend

        define_rules(:NumberingSystemRules, backend, __ENV__)
      end

      defmodule Number.Rbnf.Spellout do
        @moduledoc """
        Functions to implement the spellout rule-based-number-format rules of CLDR.

        As CLDR notes, the data is incomplete or non-existent for many languages.  It
        is considered complete for English however.

        The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

        The functions on this module are defined at compile time based upon the RBNF rules
        defined in the Unicode CLDR data repository.  Available rules are identified by:

            iex> Cldr.Rbnf.Spellout.rule_sets Cldr.Locale.new!("en")
            [:spellout_ordinal_verbose, :spellout_ordinal, :spellout_numbering_year,
              :spellout_numbering_verbose, :spellout_numbering, :spellout_cardinal_verbose,
              :spellout_cardinal]

        A rule can then be invoked on an available rule_set. For example:

            iex> Cldr.Rbnf.Spellout.spellout_ordinal 123, Cldr.Locale.new!("en")
            "one hundred twenty-third"

        This call is equivalent to the call through the public API of:

            iex> Cldr.Number.to_string 123, format: :spellout
            {:ok, "one hundred twenty-three"}

        """

        import Kernel, except: [and: 2]
        use Cldr.Rbnf.Processor, backend

        define_rules(:SpelloutRules, backend, __ENV__)

        # Default function to prevent compiler warnings in Cldr.Number
        def spellout_cardinal_verbose(_number, locale) do
          {:error, Cldr.Rbnf.rbnf_rule_error(locale, :spellout_cardinal_verbose)}
        end

        def spellout_ordinal_verbose(_number, locale) do
          {:error, Cldr.Rbnf.rbnf_rule_error(locale, :spellout_ordinal_verbose)}
        end
      end

      defmodule Number.Rbnf.Ordinal do
        @moduledoc """
        Functions to implement the ordinal rule-based-number-format rules of CLDR.

        As CLDR notes, the data is incomplete or non-existent for many languages.  It
        is considered complete for English however.

        The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

        The functions on this module are defined at compile time based upon the RBNF rules
        defined in the Unicode CLDR data repository.  Available rules are identified by:

            iex> Cldr.Rbnf.Ordinal.rule_sets Cldr.Locale.new!("en")
            [:digits_ordinal]

        A rule can then be invoked on an available rule_set.  For example

            iex> Cldr.Rbnf.Ordinal.digits_ordinal 123, Cldr.Locale.new!("en")
            "123rd"

        This call is equivalent to the call through the public API of:

            iex> Cldr.Number.to_string 123, format: :ordinal
            {:ok, "123rd"}

        """

        import Kernel, except: [and: 2]
        use Cldr.Rbnf.Processor, backend

        define_rules(:OrdinalRules, backend, __ENV__)
      end
    end
  end
end


