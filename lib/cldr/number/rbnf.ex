defmodule Cldr.Rbnf do
  @moduledoc """
  Functions to implement Rules Based Number Formatting (rbnf)

  During compilation RBNF rules are extracted and generated
  as function bodies by `Cldr.Rbnf.Ordinal`, `Cldr.Rbnf.Cardinal`
  and `Cldr.Rbnf.NumberSystem`.

  The functions in this module would not normally be of common
  use outside of supporting the compilation phase.
  """

  alias Cldr.LanguageTag

  @doc """
  Returns the list of locales that that have RBNF defined

  This list is the set of known locales for which
  there are rbnf rules defined.

  Delegates to `Cldr.known_rbnf_locale_names/1`

  """
  defdelegate known_locale_names(backend), to: Cldr, as: :known_rbnf_locale_names

  @categories [:NumberSystem, :Spellout, :Ordinal]

  @doc """
  Returns the list of RBNF rules for a locale.

  A rule name can be used as the `:format` parameter
  in `Cldr.Number.to_string/3`.

  ## Arguments

  * `locale` is any `Cldr.LanguageTag.t()`

  ## Returns

  * `{:ok, [list_of_rule_names_as_atoms]}` or

  * `{:error, {exception, reason}}`

  ## Examples

      iex> Cldr.Rbnf.rule_names_for_locale "zh"
      {:ok,
       [:spellout_cardinal_alternate2, :spellout_ordinal, :spellout_cardinal,
        :spellout_cardinal_financial, :spellout_numbering, :spellout_numbering_days,
        :spellout_numbering_year, :digits_ordinal]}

      iex> Cldr.Rbnf.rule_names_for_locale "fp"
      {:error, {Cldr.InvalidLanguageError, "The language \"fp\" is invalid"}}

  """
  @spec rule_names_for_locale(Cldr.LanguageTag.t()) ::
    {:ok, list(atom())} | {:error, {module(), String.t()}}

  def rule_names_for_locale(%LanguageTag{rbnf_locale_name: nil} = language_tag) do
    {:error, rbnf_locale_error(language_tag)}
  end

  def rule_names_for_locale(%LanguageTag{rbnf_locale_name: rbnf_locale_name, backend: backend}) do
    rule_names =
      Enum.flat_map(@categories, fn category ->
        rbnf_module = Module.concat([backend, :Rbnf, category])
        rule_names = rbnf_module.rule_sets(rbnf_locale_name)
        if rule_names, do: rule_names, else: []
      end)

    {:ok, rule_names}
  end

  def rule_names_for_locale(locale_name, backend \\ Cldr.default_backend!())
      when is_binary(locale_name) do
    with {:ok, locale} <- Cldr.Locale.canonical_language_tag(locale_name, backend) do
      rule_names_for_locale(locale)
    end
  end

  @doc """
  Returns the list of RBNF rules for a locale.

  A rule name can be used as the `:format` parameter
  in `Cldr.Number.to_string/3`.

  ## Arguments

  * `locale` is any `Cldr.LanguageTag.t()`

  ## Returns

  * `[list_of_rule_names_as_atoms]`, or

  * raises an exception

  ## Examples

      iex> Cldr.Rbnf.rule_names_for_locale! "zh"
      [:spellout_cardinal_alternate2, :spellout_ordinal, :spellout_cardinal,
       :spellout_cardinal_financial, :spellout_numbering, :spellout_numbering_days,
       :spellout_numbering_year, :digits_ordinal]

  """
  @spec rule_names_for_locale!(Cldr.LanguageTag.t()) :: list(atom()) | no_return()

  def rule_names_for_locale!(locale) do
    case rule_names_for_locale(locale) do
      {:ok, rule_names} -> rule_names
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Returns {:ok, rbnf_rules} for a `locale` or `{:error, {Cldr.NoRbnf, info}}`

  * `locale` is any `t:Cldr.LanguageTag`

  This function reads the raw locale definition and therefore
  should *not* be called at runtime.

  """
  @spec for_locale(LanguageTag.t()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def for_locale(%LanguageTag{rbnf_locale_name: nil} = language_tag) do
    {:error, rbnf_locale_error(language_tag)}
  end

  def for_locale(%LanguageTag{rbnf_locale_name: rbnf_locale_name, backend: backend}) do
    rbnf_data =
      rbnf_locale_name
      |> Cldr.Locale.Loader.get_locale(backend)
      |> Map.get(:rbnf)

    {:ok, rbnf_data}
  end

  @doc """
  Returns {:ok, rbnf_rules} for a `locale` or `{:error, {Cldr.NoRbnf, info}}`

  * `locale` is any locale name returned by `Cldr.Rbnf.known_locale_names/1`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  """
  @spec for_locale(Cldr.Locale.locale_name() | LanguageTag.t(), Cldr.backend()) ::
          {:ok, map()} | {:error, {module(), String.t()}}

  def for_locale(locale, backend) do
    with {:ok, language_tag} <- Cldr.Locale.canonical_language_tag(locale, backend) do
      for_locale(language_tag)
    end
  end

  @doc """
  Returns rbnf_rules for a `locale` or raises an exception if
  there are no rules.

  * `locale` is any `Cldr.LanguageTag`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  """
  def for_locale!(%LanguageTag{} = locale) do
    case for_locale(locale) do
      {:ok, rules} -> rules
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc """
  Returns rbnf_rules for a `locale` and `backend` or raises an exception if
  there are no rules.

  * `locale` is any locale name returned by `Cldr.Rbnf.known_locale_names/1`

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module

  """
  def for_locale!(locale, backend) when is_atom(backend) do
    case for_locale(locale, backend) do
      {:ok, rules} -> rules
      {:error, {exception, reason}} -> raise exception, reason
    end
  end

  @doc false
  def categories_for_locale!(%LanguageTag{} = locale) do
    Enum.reduce(@categories, [], fn category, acc ->
      rbnf_module = Module.concat([locale.backend, :Rbnf, category])
      case rbnf_module.rule_sets(locale) do
        nil -> acc
        _rules -> [category | acc]
      end
    end)
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
    known_rbnf_locale_names = Cldr.Locale.Loader.known_rbnf_locale_names(config)

    Enum.map(known_rbnf_locale_names, fn locale_name ->
      locale =
        locale_name
        |> Cldr.Locale.Loader.get_locale(config)
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
      |> Enum.map(&for_locale!(&1))
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
