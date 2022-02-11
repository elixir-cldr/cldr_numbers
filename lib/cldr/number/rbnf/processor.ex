defmodule Cldr.Rbnf.Processor do
  @moduledoc """
  Macro to define the interpreter for the compiled RBNF rules specific to a rule group (Ordinal,
  Spellout, NumberingSystem)

  """
  defmacro __using__(opts) do
    backend = opts[:backend]
    ordinal_module = Module.concat(backend, Number.Ordinal)
    cardinal_module = Module.concat(backend, Number.Cardinal)
    spellout_module = Module.concat(backend, Rbnf.Spellout)

    quote location: :keep do
      alias Cldr.Number
      alias Cldr.Digits
      import Cldr.Rbnf.Processor
      Module.put_attribute(__MODULE__, :backend, unquote(backend))

      defp do_rule(number, locale, function, rule, parsed) do
        results =
          Enum.map(parsed, fn {operation, argument} ->
            do_operation(operation, number, locale, function, rule, argument)
          end)

        if Enum.any?(results, fn
             {:error, _} -> true
             _ -> false
           end) do
          {:error, collect_errors(results)}
        else
          :erlang.iolist_to_binary(results)
        end
      end

      defp collect_errors(results) do
        results
        |> Enum.map(fn
          {_, v} -> v
          other -> other
        end)
        |> Enum.join(", ")
      end

      defp do_operation(:literal, _number, _locale, _function, _rule, string) do
        string
      end

      defp do_operation(:modulo, number, locale, function, rule, nil)
           when is_number(number) and number < 0 do
        apply(__MODULE__, function, [abs(number), locale])
      end

      defp do_operation(:modulo, number, locale, function, rule, {:format, format})
           when is_number(number) and number < 0 do
        Cldr.Number.to_string!(abs(number), unquote(backend), locale: locale, format: format)
      end

      defp do_operation(:modulo, number, locale, function, rule, nil)
           when is_integer(number) do
        mod = number - div(number, rule.divisor) * rule.divisor
        apply(__MODULE__, function, [mod, locale])
      end

      # For Fractional rules we format the integral part
      defp do_operation(:modulo, number, locale, function, _rule, nil)
           when is_float(number) do
        format_fraction(number, locale)
      end

      defp do_operation(:modulo, number, locale, _function, rule, {:rule, rule_name}) do
        mod = number - div(number, rule.divisor) * rule.divisor
        apply(__MODULE__, rule_name, [mod, locale])
      end

      defp do_operation(:modulo, number, locale, function, rule, {:format, format}) do
        mod = number - div(number, rule.divisor) * rule.divisor
        Cldr.Number.to_string!(mod, unquote(backend), locale: locale, format: format)
      end

      # For Fractional rules we format the fraction as individual digits.
      defp do_operation(:quotient, number, locale, function, rule, nil)
           when is_float(number) do
        apply(__MODULE__, function, [trunc(number), locale])
      end

      defp do_operation(:quotient, number, locale, function, rule, nil) do
        divisor = div(number, rule.divisor)
        apply(__MODULE__, function, [divisor, locale])
      end

      defp do_operation(:quotient, number, locale, _function, rule, {:rule, rule_name}) do
        divisor = div(number, rule.divisor)
        apply(__MODULE__, rule_name, [divisor, locale])
      end

      defp do_operation(:call, number, locale, _function, _rule, {:format, format}) do
        Cldr.Number.to_string!(number, unquote(backend), locale: locale, format: format)
      end

      defp do_operation(:call, number, locale, _function, _rule, {:rule, rule_name}) do
        apply(__MODULE__, rule_name, [number, locale])
      end

      defp do_operation(:ordinal, number, locale, _function, _rule, plurals) do
        plural = unquote(ordinal_module).plural_rule(number, locale)
        Map.get(plurals, plural) || Map.get(plurals, :other)
      end

      defp do_operation(:cardinal, number, locale, _function, _rule, plurals) do
        plural = unquote(cardinal_module).plural_rule(number, locale)
        Map.get(plurals, plural) || Map.get(plurals, :other)
      end

      defp do_operation(:conditional, number, locale, function, rule, argument) do
        mod = number - div(number, rule.divisor) * rule.divisor

        if mod > 0 do
          do_rule(mod, locale, function, rule, argument)
        else
          ""
        end
      end

      defp format_fraction(number, locale) do
        fraction =
          number
          |> Digits.fraction_as_integer()
          |> Integer.to_string()
          |> String.split("", trim: true)
          |> Enum.map(&String.to_integer/1)
          |> Enum.map(&unquote(spellout_module).spellout_cardinal(&1, locale))
          |> Enum.join(" ")
      end

      @before_compile Cldr.Rbnf.Processor
    end
  end

  @public_rulesets :public_rulesets
  def define_rules(rule_group_name, backend, env) do
    Module.register_attribute(env.module, @public_rulesets, [])

    iterate_rules(rule_group_name, backend, fn
      rule_group, locale, "public", :error ->
        define_rule(:error, nil, rule_group, locale, nil)
        |> Code.eval_quoted([], env)

      _rule_group, _locale, "private", :error ->
        nil

      rule_group, locale, "public", :redirect ->
        define_rule(:redirect, backend, rule_group, locale, nil)
        |> Code.eval_quoted([], env)

      _rule_group, _locale, "private", :redirect ->
        nil

      rule_group, locale, access, rule ->
        {:ok, parsed} = Cldr.Rbnf.Rule.parse(rule.definition)

        function_body = rule_body(locale, rule_group, rule, parsed, backend)

        rule.base_value
        |> define_rule(rule.range, rule_group, locale, function_body)
        |> add_function_to_exports(access, env.module, locale)
        |> Code.eval_quoted([], env)
    end)
  end

  defp iterate_rules(rule_group_type, backend, fun) do
    all_rules = Cldr.Rbnf.for_all_locales(backend)[rule_group_type]

    unless is_nil(all_rules) do
      for {locale_name, _rule_group} <- all_rules do
        for {rule_group, %{access: access, rules: rules}} <- all_rules[locale_name] do
          for rule <- rules do
            fun.(rule_group, locale_name, access, rule)
          end

          fun.(rule_group, locale_name, access, :redirect)
          fun.(rule_group, locale_name, access, :error)
        end
      end
    end
  end

  # If we are provided with a Decimal integer then we can call the
  # equivalent integer function without loss of precision
  defp define_rule(:error, _range, rule_group, locale_name, _body) do
    quote location: :keep do
      def unquote(rule_group)(
            %Decimal{exp: 0, coef: number},
            %Cldr.LanguageTag{rbnf_locale_name: unquote(locale_name)} = locale
          ) do
        unquote(rule_group)(number, locale)
      end

      def unquote(rule_group)(number, %Cldr.LanguageTag{rbnf_locale_name: unquote(locale_name)}) do
        {:error, rbnf_rule_error(number, unquote(rule_group), unquote(locale_name))}
      end
    end
  end

  defp define_rule(:redirect, backend, rule_group, locale_name, _body) do
    quote location: :keep do
      def unquote(rule_group)(number, unquote(locale_name)) do
        with {:ok, locale} <- Module.concat(unquote(backend), Locale).new(unquote(locale_name)) do
          unquote(rule_group)(number, locale)
        end
      end
    end
  end

  defp define_rule("-x", _range, rule_group, locale_name, body) do
    quote location: :keep do
      def unquote(rule_group)(number, %Cldr.LanguageTag{rbnf_locale_name: unquote(locale_name)})
          when Kernel.and(is_number(number), number < 0),
          do: unquote(body)
    end
  end

  # Improper fraction rule
  defp define_rule("x.x", _range, rule_group, locale_name, body) do
    quote location: :keep do
      def unquote(rule_group)(number, %Cldr.LanguageTag{rbnf_locale_name: unquote(locale_name)})
          when is_float(number),
          do: unquote(body)
    end
  end

  defp define_rule("x,x", range, rule_group, locale, body) do
    define_rule("x.x", range, rule_group, locale, body)
  end

  defp define_rule(0, "undefined", rule_group, locale_name, body) do
    quote location: :keep do
      def unquote(rule_group)(number, %Cldr.LanguageTag{rbnf_locale_name: unquote(locale_name)})
          when is_integer(number),
          do: unquote(body)
    end
  end

  defp define_rule(base_value, "undefined", rule_group, locale_name, body)
       when is_integer(base_value) do
    quote location: :keep do
      def unquote(rule_group)(number, %Cldr.LanguageTag{rbnf_locale_name: unquote(locale_name)})
          when Kernel.and(is_integer(number), number >= unquote(base_value)),
          do: unquote(body)
    end
  end

  defp define_rule(base_value, range, rule_group, locale_name, body)
       when is_integer(range) and is_integer(base_value) do
    quote location: :keep do
      def unquote(rule_group)(number, %Cldr.LanguageTag{rbnf_locale_name: unquote(locale_name)})
          when Kernel.and(
                 is_integer(number),
                 Kernel.and(number >= unquote(base_value), number < unquote(range))
               ),
          do: unquote(body)
    end
  end

  defp define_rule("Inf", _range, _rule_group, _locale_name, _body) do
    {:error, "Infinite rule sets are not implemented"}
  end

  defp define_rule("NaN", _range, _rule_group, _locale_name, _body) do
    {:error, "NaN rule sets are not implemented"}
  end

  defp define_rule("0.x", _range, _rule_group, _locale_name, _body) do
    {:error, "Proper Fraction rule sets are not implemented"}
  end

  defp define_rule("x.0", _range, _rule_group, _locale_name, _body) do
    {:error, "Master rule sets are not implemented"}
  end

  # Get the AST of the rule body
  defp rule_body(locale_name, rule_group, rule, parsed, _backend) do
    locale =
      Cldr.Config.all_language_tags()
      |> Map.get(locale_name)

    quote location: :keep do
      do_rule(
        number,
        unquote(Macro.escape(locale)),
        unquote(rule_group),
        unquote(Macro.escape(rule)),
        unquote(Macro.escape(parsed))
      )
    end
  end

  # Keep track of the public rulesets per locale so we can introspect the
  # public interface
  defp add_function_to_exports(
         {:def, _aliases, [{:when, _, [{name, _, _} | _]} | _]} = function,
         "public",
         module,
         locale
       ) do
    public_rulesets = Module.get_attribute(module, @public_rulesets) || %{}
    locale_public_rulesets = [name | Map.get(public_rulesets, locale) || []]

    Module.put_attribute(
      module,
      @public_rulesets,
      Map.put(public_rulesets, locale, Enum.uniq(locale_public_rulesets))
    )

    function
  end

  defp add_function_to_exports(other, _access, _module, _locale) do
    other
  end

  def rbnf_rule_error(number, rule_group, locale_name) do
    {
      Cldr.Rbnf.NoRuleForNumber,
      "rule group #{inspect(rule_group)} for locale #{inspect(locale_name)} does not " <>
        "know how to process #{inspect(number)}"
    }
  end

  defmacro __before_compile__(env) do
    module = env.module

    backend =
      module
      |> Module.get_attribute(:backend)

    rule_sets =
      module
      |> Module.get_attribute(:public_rulesets)

    all_rule_sets =
      rule_sets
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    rule_sets = Macro.escape(rule_sets)

    quote location: :keep,
          bind_quoted: [
            rule_sets: rule_sets,
            all_rule_sets: all_rule_sets,
            backend: backend,
            module: module] do

      # A map of rule sets by locale
      def rule_sets do
        unquote(Macro.escape(rule_sets))
      end

      # All rule sets for a locale
      def rule_sets(%Cldr.LanguageTag{rbnf_locale_name: rbnf_locale_name}) do
        rule_sets(rbnf_locale_name)
      end

      def rule_sets(rbnf_locale_name) when is_atom(rbnf_locale_name) do
        Map.get(rule_sets(), rbnf_locale_name)
      end

      def rule_sets(rbnf_locale_name) when is_binary(rbnf_locale_name) do
        rbnf_locale_name
        |> String.to_existing_atom()
        |> rule_sets
      rescue ArgumentError ->
        nil
      end

      # All rule sets for all locales
      def all_rule_sets do
        unquote(all_rule_sets)
      end

      # Return an error for a valid rule set which
      # is not supported for either the locale or
      # the number

      for rule_group <- all_rule_sets do
        @dialyzer {:nowarn_function, [{rule_group, 2}]}
        def unquote(rule_group)(number, locale_name) when is_atom(locale_name) or is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            unquote(rule_group)(number, locale)
          end
        end

        def unquote(rule_group)(number, %Cldr.LanguageTag{rbnf_locale_name: rbnf_locale_name}) do
          {:error, rbnf_rule_error(number, unquote(rule_group), rbnf_locale_name)}
        end

        # NumberSystem rules are only in the root locale so
        # lets make it easier to use them by defaulting the locale
        if hd(Enum.reverse(Module.split(module))) == "NumberSystem" do
          def unquote(rule_group)(number) do
            unquote(rule_group)(number, unquote(Cldr.Config.root_locale_name()))
          end
        end
      end
    end
  end
end
