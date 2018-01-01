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

  require Cldr
  alias Cldr.Locale
  alias Cldr.LanguageTag

  def known_locale_names do
    Cldr.known_rbnf_locale_names()
  end

  @doc """
  Returns {:ok, rbnf_rules} for a `locale` or `{:error, {Cldr.NoRbnf, info}}`

  * `locale` is any locale name returned by `Cldr.Rbnf.known_locale_names/0`.
    or a `Cldr.LanguageTag`

  """
  @spec for_locale(Locale.t()) :: %{} | nil
  def for_locale(locale \\ Cldr.get_current_locale())

  def for_locale(%LanguageTag{rbnf_locale_name: nil} = language_tag) do
    {:error, rbnf_locale_error(language_tag)}
  end

  def for_locale(%LanguageTag{rbnf_locale_name: rbnf_locale_name}) do
    rbnf_data =
      rbnf_locale_name
      |> Cldr.Config.get_locale()
      |> Map.get(:rbnf)

    {:ok, rbnf_data}
  end

  def for_locale(locale) when is_binary(locale) do
    with {:ok, language_tag} <- Cldr.Locale.canonical_language_tag(locale) do
      for_locale(language_tag)
    end
  end

  @doc """
  Returns rbnf_rules for a `locale` or raises an exception if
  there are no rules.

  * `locale` is any locale name returned by `Cldr.Rbnf.known_locale_names/0`.
    or a `Cldr.LanguageTag`

  """
  def for_locale!(locale) do
    case for_locale(locale) do
      {:ok, rules} -> rules
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Returns a map that merges all rules by the primary dimension of
  RuleGroup, within which rbnf rules are keyed by locale.

  This function is primarily intended to support compile-time generation
  of functions to process rbnf rules.
  """
  @spec for_all_locales :: %{}
  def for_all_locales do
    Enum.map(known_locale_names(), fn locale_name ->
      locale = Locale.new!(locale_name)

      Enum.map(for_locale!(locale), fn {group, sets} ->
        {group, %{locale_name => sets}}
      end)
      |> Enum.into(%{})
    end)
    |> Cldr.Map.merge_map_list()
  end

  def rbnf_locale_error(locale_name) when is_binary(locale_name) do
    {Cldr.Rbnf.NotAvailable, "RBNF is not available for the locale #{inspect(locale_name)}"}
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
    def all_rules do
      # Get sets from groups
      # Get rules from set
      # Get the list of rules
      known_locale_names()
      |> Enum.map(&Cldr.Locale.new!/1)
      |> Enum.map(&for_locale!/1)
      |> Enum.flat_map(&Map.values/1)
      |> Enum.flat_map(&Map.values/1)
      |> Enum.flat_map(& &1.rules)
    end

    # Returns a list of unique rule definitions.  Used for testing.
    @doc false
    def all_rule_definitions do
      all_rules()
      |> Enum.map(& &1.definition)
      |> Enum.uniq()
    end
  end
end
