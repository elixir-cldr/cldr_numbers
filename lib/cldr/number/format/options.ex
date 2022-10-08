defmodule Cldr.Number.Format.Options do
  @moduledoc """
  Functions to validate and transform
  options that guide number formatting
  """

  alias Cldr.Number.{System, Symbol, Format}
  alias Cldr.Number.Format.Compiler
  alias Cldr.Currency
  alias Cldr.LanguageTag

  # These are the options set in the
  # struct guide formatting
  @options [
    :locale,
    :number_system,
    :currency,
    :format,
    :currency_digits,
    :currency_spacing,
    :currency_symbol,
    :symbols,
    :minimum_grouping_digits,
    :pattern,
    :rounding_mode,
    :fractional_digits,
    :maximum_integer_digits,
    :round_nearest
  ]

  # These are the options that can be supplied
  # through the api
  @valid_options @options --
    [:currency_spacing, :pattern] ++ [:cash]

  @short_format_styles [
    :currency_short,
    :currency_long_with_symbol,
    :currency_long,
    :decimal_short,
    :decimal_long
  ]

  @rounding_modes [
    :down,
    :half_up,
    :half_even,
    :ceiling,
    :floor,
    :half_down,
    :up
  ]

  @standard_formats [
    :standard,
    :accounting,
    :currency,
    :percent
  ]

  @currency_formats [
    :currency,
    :accounting,
    :currency_long,
    :currency_long_with_symbol,
    :currency_short
  ]

  @currency_symbol [
    :standard,
    :iso,
    :narrow,
    :symbol
  ]

  @type fixed_formats :: :standard | :currency | :accounting | :short | :long
  @type format :: binary() | fixed_formats()
  @type currency_symbol :: :standard | :iso
  @type short_format_styles ::
    :currency_short | :currency_long | :currency_long_with_symbol | :decimal_short | :decimal_long

  @type t :: %__MODULE__{
    locale: LanguageTag.t(),
    number_system: System.system_name(),
    currency: Currency.code() | Currency.t(),
    format: format(),
    currency_digits: pos_integer(),
    currency_spacing: map(),
    symbols: Symbol.t(),
    minimum_grouping_digits: pos_integer(),
    pattern: String.t(),
    rounding_mode: Decimal.rounding(),
    fractional_digits: pos_integer(),
    maximum_integer_digits: pos_integer(),
    round_nearest: pos_integer()
  }

  defstruct @options

  @spec validate_options(Cldr.Math.number_or_decimal(), Cldr.backend(), list({atom, term})) ::
          {:ok, t} | {:error, {module(), String.t()}}

  def validate_options(number, backend, options) do
    with {:ok, options} <- ensure_only_valid_keys(@valid_options, options),
         {:ok, backend} <- Cldr.validate_backend(backend) do

      options =
        Module.concat(backend, Number).default_options()
        |> Keyword.merge(options)
        |> Map.new

      options
      |> maybe_adjust_currency_format(options.currency, options.format)
      |> validate_each_option(backend)
      |> resolve_standard_format(backend)
      |> confirm_currency_format_has_currency_code()
      |> set_pattern(number)
      |> maybe_set_iso_currency_symbol()
      |> structify(__MODULE__)
      |> wrap_ok()
    end
  end

  def validate_each_option(options, backend) do
    Enum.reduce_while(@options, options, fn option, options ->
      case validate_option(option, options, backend, Map.get(options, option)) do
        {:ok, result} -> {:cont, Map.put(options, option, result)}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  def wrap_ok(%__MODULE__{} = options) do
    {:ok, options}
  end

  def wrap_ok(other) do
    other
  end

  # TODO for ex_cldr_numbers 3.0
  def ensure_only_valid_keys(_valid_options, options) do
    {:ok, options}
  end

  # def ensure_only_valid_keys(valid_options, options) do
  #   option_keys = Keyword.keys(options)
  #
  #   if (invalid = (option_keys -- valid_options)) == [] do
  #     {:ok, options}
  #   else
  #     {:error, {ArgumentError, "Invalid options found: #{inspect invalid}"}}
  #   end
  # end

  # If the format is :narrpw and we have a currency then we set the currency_symbol to
  # :narrow, the format to :currency
  def maybe_adjust_currency_format(options, currency, :narrow) when not is_nil(currency) do
    options
    |> Map.put(:currency_symbol, :narrow)
    |> Map.put(:format, Currency.currency_format_from_locale(options.locale))
  end

  def maybe_adjust_currency_format(options, _currency, _format) do
    options
  end

  def resolve_standard_format(%{format: format} = options, backend)
      when format in @standard_formats do
    locale = Map.fetch!(options, :locale)
    number_system = Map.fetch!(options, :number_system)

    with {:ok, formats} <- Format.formats_for(locale, number_system, backend) do
      if resolved_format = Map.get(formats, format, format) do
        Map.put(options, :format, resolved_format)
      else
        {:error,
          {Cldr.UnknownFormatError,
            "The locale #{inspect Map.fetch!(locale, :cldr_locale_name)} " <>
            "with number system #{inspect number_system} " <>
            "does not define a format #{inspect format}"}}
      end
    end
  end

  def resolve_standard_format(other, _backend) do
    other
  end

  @currency_placeholder Compiler.placeholder(:currency)
  @iso_placeholder Compiler.placeholder(:currency) <> Compiler.placeholder(:currency)
  def confirm_currency_format_has_currency_code(%{format: format, currency: nil} = options)
      when is_binary(format) do
    if String.contains?(format, @currency_placeholder) do
      {:error,
        {Cldr.FormatError,
          "currency format #{inspect(format)} requires that " <>
          "options[:currency] be specified"}}
    else
      options
    end
  end

  def confirm_currency_format_has_currency_code(other) do
    other
  end

  def maybe_set_iso_currency_symbol(%{format: format} = options) do
    %{currency_symbol: currency_symbol} = options
    Map.put(options, :format, maybe_adjust_currency_symbol(format, currency_symbol))
  end

  def maybe_set_iso_currency_symbol(other) do
    other
  end

  def set_pattern(options, number) when is_map(options) and is_number(number) and number < 0 do
    Map.put(options, :pattern, :negative)
  end

  def set_pattern(options, %Decimal{sign: sign}) when is_map(options) and sign < 0 do
    Map.put(options, :pattern, :negative)
  end

  def set_pattern(options, _number) when is_map(options) do
    Map.put(options, :pattern, :positive)
  end

  def set_pattern(other, _number) do
    other
  end

  def structify(options, module) when is_map(options) do
    struct(module, options)
  end

  def structify(other, _module) do
    other
  end

  def validate_option(:locale, _options, backend, nil) do
    {:ok, backend.get_locale()}
  end

  def validate_option(:locale, _options, backend, locale) do
    with {:ok, locale} <- Cldr.validate_locale(locale, backend) do
      {:ok, locale}
    end
  end

  # Number system is extracted from the locale
  def validate_option(:number_system, options, backend, number_system)
      when is_nil(number_system) or number_system == :default do
    number_system =
      options
      |> Map.fetch!(:locale)
      |> System.number_system_from_locale(backend)

    {:ok, number_system}
  end

  def validate_option(:number_system, options, backend, number_system) do
    locale = Map.fetch!(options, :locale)
    System.system_name_from(number_system, locale, backend)
  end

  def validate_option(:currency, %{format: format, locale: locale}, _backend, nil)
      when format in @currency_formats do
    {:ok, Cldr.Currency.currency_from_locale(locale)}
  end

  def validate_option(:currency, %{format: format, locale: locale}, _backend, nil)
      when is_binary(format) do
    if String.contains?(format, @currency_placeholder) do
      {:ok, Cldr.Currency.currency_from_locale(locale)}
    else
      {:ok, nil}
    end
  end

  def validate_option(:currency, _options, _backend, nil) do
    {:ok, nil}
  end

  def validate_option(:currency, _options, _backend, %Cldr.Currency{} = currency) do
    {:ok, currency}
  end

  def validate_option(:currency, _options, _backend, currency) do
    with {:ok, currency} <- Cldr.validate_currency(currency) do
      {:ok, currency}
    else
      {:error, _} ->
        case DigitalToken.validate_token(currency) do
          {:ok, token} -> {:ok, token}
          {:error, _} -> {:error, Cldr.unknown_currency_error(currency)}
        end
    end
  end

  # If a currency code is provided then a currency
  # format is forced
  def validate_option(:format, options, _backend, nil) do
    locale = Map.fetch!(options, :locale)

    if Map.fetch!(options, :currency) do
      {:ok, Currency.currency_format_from_locale(locale)}
    else
      {:ok, :standard}
    end
  end

  def validate_option(:format, options, _backend, :short) do
    if Map.get(options, :currency) do
      {:ok, :currency_short}
    else
      {:ok, :decimal_short}
    end
  end

  def validate_option(:format, options, _backend, :long) do
    if Map.get(options, :currency) do
      {:ok, :currency_long}
    else
      {:ok, :decimal_long}
    end
  end

  @exclude_formats [:accounting, :currency_short, :currency_long, :currency_long_with_symbol]

  def validate_option(:format, options, _backend, format)
      when is_atom(format) and format not in @exclude_formats do
    locale = Map.fetch!(options, :locale)

    if Map.get(options, :currency) do
      {:ok, Currency.currency_format_from_locale(locale)}
    else
      {:ok, format}
    end
  end

  def validate_option(:format, _options, _backend, format) do
    {:ok, format}
  end

  # Currency digits is an opaque option that is a proxy
  # for the `:cash` parameter which is set to true or false
  def validate_option(:currency_digits, options, _backend, _currency_digits) do
    if Map.get(options, :cash) do
      {:ok, :cash}
    else
      {:ok, :accounting}
    end
  end

  # Currency spacing isn't really a user option
  # Its derived for currency formats only
  def validate_option(:currency_spacing, %{format: format} = options, backend, _spacing)
      when format in [:currency, :accounting, :currency_short] do
    locale = Map.fetch!(options, :locale)
    number_system = Map.fetch!(options, :number_system)
    module = Module.concat(backend, Number.Format)

    {:ok, module.currency_spacing(locale, number_system)}
  end

  def validate_option(:currency_spacing, _options, _backend, _currency_spacing) do
    {:ok, nil}
  end

  def validate_option(:currency_symbol, _options, _backend, nil) do
    {:ok, nil}
  end

  def validate_option(:currency_symbol, _options, _backend, currency_symbol)
      when currency_symbol in @currency_symbol do
    {:ok, currency_symbol}
  end

  def validate_option(:currency_symbol, _options, _backend, currency_symbol)
      when is_binary(currency_symbol) do
    {:ok, currency_symbol}
  end

  def validate_option(:currency_symbol, _options, _backend, other) do
    {:error,
      {ArgumentError,
        ":currency_symbol must be :standard, :iso, :narrow, :symbol, " <>
        "a string or nil. Found #{inspect other}"
    }}
  end

  def validate_option(:symbols, options, backend, _any) do
    locale = Map.fetch!(options, :locale)
    number_system = Map.fetch!(options, :number_system)

    case Symbol.number_symbols_for(locale, number_system, backend) do
      {:ok, symbols} -> {:ok, symbols}
      _other -> {:ok, nil}
    end
  end

  def validate_option(:minimum_grouping_digits, _options, _backend, nil) do
    {:ok, 0}
  end

  def validate_option(:minimum_grouping_digits, _options, _backend, int)
      when is_integer(int) and int >= 0 do
    {:ok, int}
  end

  def validate_option(:minimum_grouping_digits, _options, _backend, other) do
    {:error,
      {ArgumentError,
        ":minimum_grouping_digits must be a positive integer or nil. Found #{inspect other}"}}
  end

  def validate_option(:fractional_digits, _options, _backend, nil) do
    {:ok, nil}
  end

  def validate_option(:fractional_digits, _options, _backend, int)
      when is_integer(int) and int >= 0 do
    {:ok, int}
  end

  def validate_option(:fractional_digits, _options, _backend, other) do
    {:error,
      {ArgumentError,
        ":fractional_digits must be a an integer >= 0 or nil. Found #{inspect other}"}}
  end

  def validate_option(:maximum_integer_digits, _options, _backend, nil) do
    {:ok, nil}
  end

  def validate_option(:maximum_integer_digits, _options, _backend, int)
      when is_integer(int) and int >= 0 do
    {:ok, int}
  end

  def validate_option(:maximum_integer_digits, _options, _backend, other) do
    {:error,
      {ArgumentError,
        ":maximum_integer_digits must be a an integer >= 0 or nil. Found #{inspect other}"}}
  end

  def validate_option(:round_nearest, _options, _backend, nil) do
    {:ok, nil}
  end

  def validate_option(:round_nearest, _options, _backend, int)
      when is_integer(int) and int > 0 do
    {:ok, int}
  end

  def validate_option(:round_nearest, _options, _backend, other) do
    {:error,
      {ArgumentError,
        ":round_nearest must be a positive integer or nil. Found #{inspect other}"}}
  end

  def validate_option(:rounding_mode, _options, _backend, nil) do
    {:ok, :half_even}
  end

  def validate_option(:rounding_mode, _options, _backend, rounding_mode)
      when rounding_mode in @rounding_modes do
    {:ok, rounding_mode}
  end

  def validate_option(:rounding_mode, _options, _backend, other) do
    {:error,
      {ArgumentError,
        ":rounding_mode must be one of #{inspect @rounding_modes}. Found #{inspect other}"}}
  end

  def validate_option(:pattern, _options, _backend, _pattern) do
    {:ok, nil}
  end

  @spec short_format_styles() :: list(atom())
  def short_format_styles do
    @short_format_styles
  end

  @doc false
  # Sometimes we want the standard format for a currency but we want the
  # ISO code instead of the currency symbol
  def maybe_adjust_currency_symbol(format, :iso) when is_binary(format) do
    String.replace(format, @currency_placeholder, @iso_placeholder)
  end

  def maybe_adjust_currency_symbol(format, _currency_symbol) do
    format
  end

  # ========= This is here for compatibility and needs review =========

  def validate_other_format(other_type, backend, options) do
    format_module = Module.concat(backend, Number.Format)

    with {:ok, formats} <- format_module.formats_for(options.locale, options.number_system) do
      if format = Map.get(formats.other, other_type) do
        {:ok, format}
      else
        locale_name = options.locale.cldr_locale_name

        {
          :error,
          {
            Cldr.UnknownFormatError,
            "The locale #{inspect(locale_name)} with number system " <>
              "#{inspect(options[:number_system])} does not define a format " <>
              "#{inspect(other_type)}."
          }
        }
      end
    end
  end
  #

end
