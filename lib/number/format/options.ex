defmodule Cldr.Number.Format.Options do
  defstruct [
    :currency,
    :currency_digits,
    :currency_spacing,
    :currency_symbol,
    :format,
    :locale,
    :minimum_grouping_digits,
    :number_system,
    :pattern,
    :rounding_mode,
    :fractional_digits,
    :symbols
  ]

  @type t :: %__MODULE__{}

  @short_format_styles [
    :currency_short,
    :currency_long,
    :decimal_short,
    :decimal_long
  ]

  @type short_format_styles :: :currency_short | :currency_long | :decimal_short | :decimal_long

  alias Cldr.Number.System
  alias Cldr.Number.Format
  alias Cldr.Number.Format.Compiler

  import Cldr.Number.Symbol, only: [number_symbols_for: 3]

  @spec validate_options(Cldr.Math.number_or_decimal(), Cldr.backend(), list({atom, term})) ::
          {:ok, t} | {:error, {module(), String.t()}}

  def validate_options(number, backend, options) do
    with {:ok, options} <- merge_default_options(backend, options),
         {:ok, options} <- validate_locale(backend, options),
         {:ok, options} <- normalize_options(backend, options),
         {:ok, options} <- validate_number_system(backend, options),
         {:ok, options} <- validate_currency_options(backend, options),
         {:ok, options} <- detect_negative_number(number, options),
         {:ok, options} <- put_number_symbols(backend, options) do
      {:ok, struct(__MODULE__, options)}
    end
  end

  # Merge options and default options with supplied options always
  # the winner.  If :currency is specified then the default :format
  # will be format: currency
  defp merge_default_options(backend, options) do
    new_options =
      Module.concat(backend, Number).default_options()
      |> merge(options, fn _k, _v1, v2 -> v2 end)
      |> adjust_for_currency(options[:currency], options[:format])

    {:ok, new_options}
  end

  @spec validate_locale(Cldr.backend(), t()) ::
          {:ok, t()} | {:error, {module(), String.t()}}

  defp validate_locale(backend, options) do
    with {:ok, locale} <- backend.validate_locale(options[:locale]) do
      options = Map.put(options, :locale, locale)
      {:ok, options}
    end
  end

  defp normalize_options(backend, options) do
    options =
      options
      |> Map.new()
      |> format_from_locale_or_options
      |> set_currency_digits
      |> resolve_standard_format(backend)
      |> adjust_short_forms
      |> maybe_use_locale_number_system()

    {:ok, options}
  end

  @spec format_from_locale_or_options(t()) :: t()

  defp format_from_locale_or_options(%{format: format} = options) when format in [:currency, :accounting] do
    case options do
      %{locale: %{locale: %{currency_format: "standard"}}} ->
        Map.put(options, :format, :currency)
      %{locale: %{locale: %{currency_format: "account"}}} ->
        Map.put(options, :format, :accounting)
      _ ->
        options
    end
  end

  defp format_from_locale_or_options(options) do
    options
  end

  @spec maybe_use_locale_number_system(t()) :: t()

  defp maybe_use_locale_number_system(%{locale: %{locale: %{number_system: number_system}}} = options) do
    if options.number_system == :default do
      Map.put(options, :number_system, number_system)
    else
      options
    end
  end

  defp maybe_use_locale_number_system(options) do
    options
  end

  @spec validate_number_system(Cldr.backend(), t()) ::
          {:ok, t()} | {:error, {module(), String.t()}}

  defp validate_number_system(backend, options) do
    locale = options.locale
    number_system = options.number_system

    with {:ok, system} <- System.system_name_from(number_system, locale, backend) do
      options = Map.put(options, :number_system, system)
      {:ok, options}
    end
  end

  @spec validate_currency_options(Cldr.backend(), t()) ::
          {:ok, t()} | {:error, {module(), String.t()}}

  defp validate_currency_options(backend, options) do
    format = Map.get(options, :format)
    currency = currency_from_locale_or_options(options)
    currency_symbol = Map.get(options, :currency_symbol, :standard)
    currency_format? = currency_format?(format)

    with {:ok, _currency} <- currency_format_has_code(format, currency_format?, currency) do
      options =
        options
        |> Map.put(:currency, currency)
        |> Map.put(:format, format)
        |> Map.put(:currency_spacing, currency_spacing(backend, options))
        |> Map.put(:format, maybe_adjust_currency_symbol(format, currency_symbol))

      {:ok, options}
    end
  end

  defp currency_from_locale_or_options(%{currency: currency}) when not is_nil(currency) do
    currency
  end

  defp currency_from_locale_or_options(%{locale: %{locale: %{currency: currency}}}) do
    currency
  end

  defp currency_from_locale_or_options(_options) do
    nil
  end

  @doc false
  # Sometimes we want the standard format for a currency but we want the
  # ISO code instead of the currency symbol
  @currency_placeholder Compiler.placeholder(:currency)
  @iso_placeholder Compiler.placeholder(:currency) <> Compiler.placeholder(:currency)
  def maybe_adjust_currency_symbol(format, :iso) when is_binary(format) do
    String.replace(format, @currency_placeholder, @iso_placeholder)
  end

  def maybe_adjust_currency_symbol(format, _currency_symbol) do
    format
  end

  @spec detect_negative_number(Cldr.Math.number_or_decimal(), t()) ::
          {:ok, t()}

  defp detect_negative_number(number, options)
       when (is_float(number) or is_integer(number)) and number < 0 do
    {:ok, Map.put(options, :pattern, :negative)}
  end

  defp detect_negative_number(%Decimal{sign: sign}, options)
       when sign < 0 do
    {:ok, Map.put(options, :pattern, :negative)}
  end

  defp detect_negative_number(_number, options) do
    {:ok, Map.put(options, :pattern, :positive)}
  end

  @spec put_number_symbols(Cldr.backend(), t()) ::
          {:ok, t()} | {:error, {module(), String.t()}}

  defp put_number_symbols(backend, options) do
    with {:ok, symbols} <- number_symbols_for(options.locale, options.number_system, backend) do
      {:ok, Map.put(options, :symbols, symbols)}
    else
      {:error, _} ->
        cldr_locale_name = options.locale.cldr_locale_name

        {
          :error,
          {
            Cldr.UnknownFormatError,
            "The locale #{inspect(cldr_locale_name)} with number system " <>
              "#{inspect(options.number_system)} does not define a format " <>
              "#{inspect(options.format)}."
          }
        }
    end
  end

  #
  # Helpers
  #

  defp currency_spacing(backend, options) do
    module = Module.concat(backend, Number.Format)
    module.currency_spacing(options[:locale], options[:number_system])
  end

  defp merge(defaults, options, fun) when is_list(options) do
    defaults
    |> Keyword.merge(options, fun)
    |> Cldr.Map.from_keyword()
  end

  defp merge(defaults, options, fun) when is_map(options) do
    defaults
    |> Cldr.Map.from_keyword()
    |> Map.merge(options, fun)
  end

  @doc false
  def resolve_standard_format(%{format: format} = options, _backend)
      when format in @short_format_styles do
    options
  end

  def resolve_standard_format(options, backend) do
    format =
      options
      |> Map.get(:format)
      |> lookup_standard_format(backend, options)

    Map.put(options, :format, format)
  end

  defp adjust_short_forms(options) do
    options
    |> check_options(:short, options[:currency], :currency_short)
    |> check_options(:long, options[:currency], :currency_long)
    |> check_options(:short, !options[:currency], :decimal_short)
    |> check_options(:long, !options[:currency], :decimal_long)
  end

  # If no format is specified but a currency is,
  # force the format to be :currency
  defp adjust_for_currency(options, currency, nil) when not is_nil(currency) do
    Map.put(options, :format, :currency)
  end

  defp adjust_for_currency(options, _currency, _format) do
    options
  end

  # We use the option `:cash` to decide if we
  # want to use cash digits or accounting digits
  defp set_currency_digits(%{cash: true} = options) do
    options
    |> Map.delete(:cash)
    |> Map.put(:currency_digits, :cash)
  end

  defp set_currency_digits(%{cash: false} = options) do
    options
    |> Map.delete(:cash)
    |> Map.put(:currency_digits, :accounting)
  end

  defp set_currency_digits(%{currency_digits: _mode} = options) do
    options
  end

  defp set_currency_digits(options) do
    options
    |> Map.put(:currency_digits, :accounting)
  end

  @doc false
  def lookup_standard_format(format, backend, options) when is_atom(format) do
    locale = Map.get(options, :locale)
    number_system = Map.get(options, :number_system)
    options_format = Map.get(options, :format)

    with {:ok, formats} <- Format.formats_for(locale, number_system, backend) do
      Map.get(formats, format) || options_format
    end
  end

  def lookup_standard_format(format, _backend, _options) when is_binary(format) do
    format
  end

  # if the format is :short or :long then we set the full format name
  # based upon whether there is a :currency set in options or not.
  defp check_options(options, format, check, finally) do
    if options[:format] == format && check do
      Map.put(options, :format, finally)
    else
      options
    end
  end

  defp currency_format_has_code(format, true, nil) do
    {
      :error,
      {
        Cldr.FormatError,
        "currency format #{inspect(format)} requires that " <> "options[:currency] be specified"
      }
    }
  end

  defp currency_format_has_code(_format, true, currency) do
    Cldr.validate_currency(currency)
  end

  defp currency_format_has_code(_format, _boolean, currency) do
    {:ok, currency}
  end

  defp currency_format?(format) when is_atom(format) do
    format == :currency_short
  end

  defp currency_format?(format) when is_binary(format) do
    String.contains?(format, @currency_placeholder)
  end

  defp currency_format?(_format) do
    false
  end

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

  @spec short_format_styles() :: list(atom())
  def short_format_styles do
    @short_format_styles
  end
end
