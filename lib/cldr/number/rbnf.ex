defmodule Cldr.Rbnf do
  @moduledoc """
  Functions to implement Rules Based Number Formatting (rbnf)

  During compilation RBNF rules are extracted and generated
  as function bodies by `Cldr.Rbnf.Ordinal`, `Cldr.Rbnf.Cardinal`
  and `Cldr.Rbnf.NumberSystem`.

  The functions in this module would not normally be of common
  use outside of supporting the compilation phase.
  """

  @doc """
  Returns the list of locales that that have RBNF defined

  This list is the set of known locales for which
  there are rbnf rules defined.
  """

  alias Cldr.LanguageTag

  def known_locale_names(backend) do
    Cldr.known_rbnf_locale_names(backend)
  end

  @doc """
  Returns {:ok, rbnf_rules} for a `locale` or `{:error, {Cldr.NoRbnf, info}}`

  * `locale` is any locale name returned by `Cldr.Rbnf.known_locale_names/1`.
    or a `Cldr.LanguageTag`

  """
  @spec for_locale(Cldr.Locale.locale_name() | LanguageTag.t(), Cldr.backend()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def for_locale(%LanguageTag{rbnf_locale_name: nil} = language_tag, _backend) do
    {:error, rbnf_locale_error(language_tag)}
  end

  def for_locale(%LanguageTag{rbnf_locale_name: rbnf_locale_name}, backend) do
    rbnf_data =
      rbnf_locale_name
      |> Cldr.Config.get_locale(backend)
      |> Map.get(:rbnf)

    {:ok, rbnf_data}
  end

  def for_locale(locale, backend) when is_binary(locale) do
    with {:ok, language_tag} <- Cldr.Locale.canonical_language_tag(locale, backend) do
      for_locale(language_tag, backend)
    end
  end

  @doc """
  Returns rbnf_rules for a `locale` or raises an exception if
  there are no rules.

  * `locale` is any locale name returned by `Cldr.Rbnf.known_locale_names/1`.
    or a `Cldr.LanguageTag`

  """
  def for_locale!(locale, backend) do
    case for_locale(locale, backend) do
      {:ok, rules} -> rules
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  # Returns a map that merges all rules by the primary dimension of
  # RuleGroup, within which rbnf rules are keyed by locale.
  #
  # This function is primarily intended to support compile-time generation
  # of functions to process rbnf rules.
  @doc false
  @spec for_all_locales(Cldr.backend()) :: %{}
  def for_all_locales(backend) do
    config = Module.get_attribute(backend, :config)
    known_rbnf_locale_names = Cldr.Config.known_rbnf_locale_names(config)

    Enum.map(known_rbnf_locale_names, fn locale_name ->
      locale =
        locale_name
        |> Cldr.Config.get_locale(config)
        |> Map.get(:rbnf)

      Enum.map(locale, fn {group, sets} ->
        {group, %{locale_name => sets}}
      end)
      |> Enum.into(%{})
    end)
    |> Cldr.Map.merge_map_list()
  end

  def rbnf_locale_error(locale_name) when is_binary(locale_name) do
    {Cldr.Rbnf.NotAvailable, "RBNF is not available for the locale #{inspect(locale_name)}"}
  end

  def rbnf_locale_error(%LanguageTag{cldr_locale_name: locale_name}) do
    rbnf_locale_error(locale_name)
  end

  def rbnf_rule_error(
        %LanguageTag{rbnf_locale_name: nil, cldr_locale_name: cldr_locale_name},
        _format
      ) do
    {Cldr.Rbnf.NotAvailable, "RBNF is not available for the locale #{inspect(cldr_locale_name)}"}
  end

  def rbnf_rule_error(%LanguageTag{rbnf_locale_name: rbnf_locale_name}, format) do
    {
      Cldr.Rbnf.NoRule,
      "Locale #{inspect(rbnf_locale_name)} does not define an rbnf ruleset #{inspect(format)}"
    }
  end

  if Mix.env() == :test do
    # Returns all the rules in rbnf without any tagging for rulegroup or set.
    # This is helpful for testing only.
    @doc false
    def all_rules(backend) do
      # Get sets from groups
      # Get rules from set
      # Get the list of rules
      known_locale_names(backend)
      |> Enum.map(&Cldr.Locale.new!(&1, backend))
      |> Enum.map(&for_locale!(&1, backend))
      |> Enum.flat_map(&Map.values/1)
      |> Enum.flat_map(&Map.values/1)
      |> Enum.flat_map(& &1.rules)
    end

    # Returns a list of unique rule definitions.  Used for testing.
    @doc false
    def all_rule_definitions(backend) do
      all_rules(backend)
      |> Enum.map(& &1.definition)
      |> Enum.uniq()
    end
  end
end
