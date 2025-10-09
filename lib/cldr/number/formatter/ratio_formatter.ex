defmodule Cldr.Number.Formatter.Ratio do
  @moduledoc false

  alias Cldr.Number.Format.Options
  alias Cldr.Substitution

  @superscript_map %{
    "0" =>  "⁰",
    "1" =>  "¹",
    "2" =>  "²",
    "3" =>  "³",
    "4" =>  "⁴",
    "5" =>  "⁵",
    "6" =>  "⁶",
    "7" =>  "⁷",
    "8" =>  "⁸",
    "9" =>  "⁹"
  }

  @subscript_map %{
    "0" =>  "₀",
    "1" =>  "₁",
    "2" =>  "₂",
    "3" =>  "₃",
    "4" =>  "₄",
    "5" =>  "₅",
    "6" =>  "₆",
    "7" =>  "₇",
    "8" =>  "₈",
    "9" =>  "₉"
  }

  def to_ratio_string(number, backend, options) when is_number(number) do
    format_backend = Module.concat(backend, Number.Format)

    with {:ok, ratio_options, number_options} <- Options.validate_ratio_options(number, backend, options),
         {:ok, formats} <- format_backend.formats_for(number_options.locale, number_options.number_system),
         {:ok, ratio_formats} <- rational_formats(formats, number_options.locale) do
      case number_to_integer_and_fraction(number) do
        {integer, fraction} when integer == 0 and fraction == 0.0 ->
          to_string(number)

        {integer, fraction} when integer == 0 and fraction != 0.0 ->
          format_fraction(fraction, ratio_formats, backend, ratio_options, number_options)

        {integer, fraction} ->
          format_integer_and_fraction(integer, fraction, ratio_formats, backend, ratio_options, number_options)
      end
    end
  end

  defp rational_formats(%{rational: nil}, locale) do
    {:error, {Cldr.Number.NoRationalFormatError,
      "No rational formats defined for locale #{inspect locale}"}}
  end

  defp rational_formats(%{rational: rational_formats}, _locale) do
    {:ok, rational_formats}
  end

  defp number_to_integer_and_fraction(number) when is_integer(number) do
    {number, 0.0}
  end

  defp number_to_integer_and_fraction(number) do
    integer = trunc(number)
    fraction = number - integer

    {integer, fraction}
  end

  defp format_integer_and_fraction(integer, fraction, formats, backend, ratio_options, number_options) do
    fraction_options =
      if integer > 0, do: number_options, else: Map.put(number_options, :pattern, :positive)

    with {:ok, integer_string} <-
            Cldr.Number.to_string(integer, backend, number_options),
         {:ok, fraction_string} <-
            format_fraction(fraction, formats, backend, ratio_options, fraction_options) do

      ratio_format =
        if :super_sub in ratio_options[:prefer],
          do: formats.integer_and_rational_pattern.super_sub,
          else: formats.integer_and_rational_pattern.default

      formatted = Substitution.substitute([integer_string, fraction_string], ratio_format)
      {:ok, List.to_string(formatted)}
    end
  end

  defp format_fraction(fraction, formats, backend, ratio_options, number_options) do
    with {numerator, denominator} <- Cldr.Math.float_to_ratio(fraction, ratio_options) do
      prefer_precomposed? = :precomposed in ratio_options[:prefer]
      format_fraction({numerator, denominator}, formats, backend, ratio_options, number_options, prefer_precomposed?)
    else _other ->
        {:error, {Cldr.Number.FloatToFractionError,
          "Could not convert #{inspect fraction} into a ratio"}}
    end
  end

  @precomposed_map %{
    {1, 4} => "¼",
    {1, 2} => "½",
    {1, 7} => "⅐",
    {1, 9} => "⅑",
    {1, 10} => "⅒",
    {1, 3} => "⅓",
    {2, 3} => "⅔",
    {1, 5} => "⅕",
    {2, 5} => "⅖",
    {3, 5} => "⅗",
    {4, 5} => "⅘",
    {1, 6} => "⅙",
    {5, 6} => "⅚",
    {1, 8} => "⅛",
    {3, 8} => "⅜",
    {5, 8} => "⅝",
    {7, 8} => "⅞"
  }

  @precomposed_map_keys Map.keys(@precomposed_map)

  defp format_fraction(fraction, _formats, _backend, _ratio_options, _number_options, true = _precomposed?)
      when fraction in @precomposed_map_keys do
    Map.fetch(@precomposed_map, fraction)
  end

  defp format_fraction({numerator, denominator}, formats, backend, ratio_options, number_options, _precomposed?) do
    denominator_options = Map.put(number_options, :pattern, :positive)

    with {:ok, numerator_string} <- Cldr.Number.to_string(numerator, backend, number_options),
         {:ok, denominator_string} <- Cldr.Number.to_string(denominator, backend, denominator_options) do

      fraction_format =
        formats.rational_pattern.default

      fraction_parts =
        [numerator_string, denominator_string]
        |> maybe_apply_super_subscript(:super_sub in ratio_options[:prefer])

      fraction_string = Substitution.substitute(fraction_parts, fraction_format)
      {:ok, List.to_string(fraction_string)}
    end
  end

  defp maybe_apply_super_subscript(result, false) do
    result
  end

  defp maybe_apply_super_subscript([numerator, denominator], true) do
    [map_superscript(numerator), map_subscript(denominator)]
  end

  defp map_superscript(string) do
    string
    |> String.graphemes()
    |> Enum.map(fn grapheme -> Map.get(@superscript_map, grapheme, grapheme) end)
    |> List.to_string()
  end

  defp map_subscript(string) do
    string
    |> String.graphemes()
    |> Enum.map(fn grapheme -> Map.get(@subscript_map, grapheme, grapheme) end)
    |> List.to_string()
  end
end