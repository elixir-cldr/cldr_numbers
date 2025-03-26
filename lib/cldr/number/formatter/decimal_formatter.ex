defmodule Cldr.Number.Formatter.Decimal do
  @moduledoc """
  Formats a number according to a locale-specific predefined format or a user-defined format.

  As a performance optimization, all decimal formats known at compile time are
  compiled into function that roughly halves the time to format a number
  compared to a non-precompiled format.

  The available format styles for a locale can be returned by:

      iex> {:ok, decimal_format_styles} = Cldr.Number.Format.decimal_format_styles_for("en", :latn, TestBackend.Cldr)
      iex> Enum.sort(decimal_format_styles)
      [
        :accounting,
        :accounting_alpha_next_to_number,
        :accounting_no_symbol,
        :currency,
        :currency_alpha_next_to_number,
        :currency_long,
        :currency_no_symbol,
        :percent,
        :scientific,
        :standard
      ]

  This allows a number to be formatted in a locale-specific way but using
  a standard method of describing the purpose of the format.

  """
  import Cldr.Math, only: [power_of_10: 1]
  import DigitalToken, only: [is_digital_token: 1]

  alias Cldr.{Currency, Math, Digits}
  alias Cldr.Number.Format
  alias Cldr.Number.Format.Compiler
  alias Cldr.Number.Format.Options

  @empty_string ""
  @max_token_fractional_digits 18

  @doc """
  Formats a number according to a decimal format string.

  This is a lower level formatting function. It is strongly
  advised to use `Cldr.Number.to_string/2` or even better the
  `MyApp.Cldr.Number.to_string/2` function where `MyApp.Cldr`
  is a Cldr backend module.

  ## Arguments

  * `number` is an integer, float or Decimal or a string. A string
    is used only when composing formats.

  * `format` is a format string.  See `Cldr.Number` for further
    information.

  * `backend` is any module that includes `use Cldr` and therefore
    is a `Cldr` backend module.

  * `options` is a `t:Cldr.Number.Format.Options.t/0` of validated options.
    See `Cldr.Number.to_string/2` for further information.

  """

  @spec to_string(Math.number_or_decimal() | String.t(), String.t(), Cldr.backend(), Options.t()) ::
          {:ok, String.t()} | {:error, {atom, String.t()}}

  def to_string(number, format, backend, %Options{} = options) when is_binary(format) do
    Module.concat(backend, Number.Formatter.Decimal).to_string(number, format, options)
  end

  @doc false
  def update_meta(meta, number, backend, options) do
    meta
    |> adjust_fraction_for_currency(options.currency, options.currency_digits, backend)
    |> adjust_fraction_for_significant_digits(number)
    |> adjust_for_fractional_digits(options.fractional_digits)
    |> adjust_for_integer_digits(options.maximum_integer_digits)
    |> adjust_for_round_nearest(options.round_nearest)
    |> Map.put(:number, number)
  end

  @doc false

  # Formatting for NaN and Inf

  def do_to_string(%Decimal{coef: :NaN}, meta, backend, options) do
    options.symbols.nan
    |> assemble_format(meta, backend, options)
  end

  def do_to_string(%Decimal{coef: :inf}, meta, backend, options) do
    options.symbols.infinity
    |> assemble_format(meta, backend, options)
  end

  # For when the number is actually a string. This allows formats to be
  # composed.

  def do_to_string(string, meta, backend, options) when is_binary(string) do
    assemble_format(string, meta, backend, options)
  end

  # For most number formats. Note this pipleine is only used for
  # formats that are compiled at runtime. For all known formats that
  # are compiled at compile time, their pipeline is baked into the
  # backend code (see define_to_string/1 in this module).

  def do_to_string(number, %{integer_digits: _integer_digits} = meta, backend, options) do
    number
    |> absolute_value(meta, backend, options)
    |> multiply_by_factor(meta, backend, options)
    |> round_to_significant_digits(meta, backend, options)
    |> round_to_nearest(meta, backend, options)
    |> set_exponent(meta, backend, options)
    |> round_fractional_digits(meta, backend, options)
    |> output_to_tuple(meta, backend, options)
    |> adjust_leading_zeros(meta, backend, options)
    |> adjust_trailing_zeros(meta, backend, options)
    |> set_max_integer_digits(meta, backend, options)
    |> apply_grouping(meta, backend, options)
    |> reassemble_number_string(meta, backend, options)
    |> transliterate(meta, backend, options)
    |> assemble_format(meta, backend, options)
  end

  # For when the format itself actually has only literal components
  # and no number format.

  def do_to_string(number, meta, backend, options) do
    assemble_format(number, meta, backend, options)
  end

  # We work with the absolute value because the formatting of the sign
  # is done by selecting the "negative format" rather than the "positive format"

  @doc false
  def absolute_value(%Decimal{} = number, _meta, _backend, _options) do
    Decimal.abs(number)
  end

  def absolute_value(number, _meta, _backend, _options) do
    abs(number)
  end

  # If the format includes a % (percent) or permille then we
  # adjust the number by a factor.  All other formats the factor
  # is 1 and hence we avoid the multiplication.

  @doc false
  def multiply_by_factor(number, %{multiplier: 1}, _backend, _options) do
    number
  end

  def multiply_by_factor(%Decimal{} = number, %{multiplier: factor}, _backend, _options)
      when is_integer(factor) do
    Decimal.mult(number, Decimal.new(factor))
  end

  def multiply_by_factor(number, %{multiplier: factor}, _backend, _options)
      when is_number(number) and is_integer(factor) do
    number * factor
  end

  # Round to significant digits.  This is different to rounding
  # to decimal places and is a more expensive mathematical
  # calculation.  Although the specification allows for minimum
  # and maximum, I haven't found an example of where minimum is a
  # useful rounding value since maximum already removes trailing
  # insignificant zeros.
  #
  # Also note that this implementation allows for both significant
  # digit rounding as well as decimal precision rounding.  Its likely
  # not a good idea to combine the two in a format mask and results
  # are unspecified if you do.

  @doc false
  def round_to_significant_digits(
        number,
        %{significant_digits: %{min: 0, max: 0}},
        _backend,
        _options
      ) do
    number
  end

  def round_to_significant_digits(
        number,
        %{significant_digits: %{min: _min, max: max}},
        _backend,
        _options
      ) do
    Math.round_significant(number, max)
  end

  # Round to nearest rounds a number to the nearest increment specified.  For example
  # if `rounding: 5` then we round to the nearest multiple of 5.  The appropriate rounding
  # mode is used.

  @doc false
  def round_to_nearest(number, %{round_nearest: rounding}, _backend, %{
        rounding_mode: _rounding_mode
      })
      when rounding == 0 do
    number
  end

  def round_to_nearest(%Decimal{} = number, %{round_nearest: rounding}, _backend, %{
        rounding_mode: rounding_mode
      }) do
    rounding = Decimal.new(rounding)

    number
    |> Decimal.div(rounding)
    |> Math.round(0, rounding_mode)
    |> Decimal.mult(rounding)
  end

  def round_to_nearest(number, %{round_nearest: rounding}, _backend, %{
        rounding_mode: rounding_mode
      })
      when is_float(number) do
    number
    |> Kernel./(rounding)
    |> Math.round(0, rounding_mode)
    |> Kernel.*(rounding)
  end

  def round_to_nearest(number, %{round_nearest: rounding}, _backend, %{
        rounding_mode: rounding_mode
      })
      when is_integer(number) do
    number
    |> Kernel./(rounding)
    |> Math.round(0, rounding_mode)
    |> Kernel.*(rounding)
    |> trunc
  end

  # For a scientific format we need to adjust to a
  # coefficient * 10^exponent format.

  @doc false
  def set_exponent(number, %{exponent_digits: 0}, _backend, _options) do
    {number, 0}
  end

  def set_exponent(number, meta, _backend, _options) do
    {coef, exponent} = Math.coef_exponent(number)
    coef = Math.round_significant(coef, meta.scientific_rounding)
    {coef, exponent}
  end

  # Round to get the right number of fractional digits.  This is
  # applied after setting the exponent since we may have either
  # the original number or its coef/exponentform.

  @doc false
  def round_fractional_digits({number, exponent}, _meta, _backend, _options)
      when is_integer(number) do
    {number, exponent}
  end

  # Don't round if we're in exponential mode.  This is probably incorrect since
  # we're not following the 'significant digits' processing rule for
  # exponent numbers.
  def round_fractional_digits(
        {number, exponent},
        %{exponent_digits: exponent_digits},
        _backend,
        _options
      )
      when exponent_digits > 0 do
    {number, exponent}
  end

  def round_fractional_digits(
        {number, exponent},
        %{fractional_digits: %{max: max, min: _min}},
        _backend,
        %{rounding_mode: rounding_mode}
      ) do
    number = Math.round(number, max, rounding_mode)
    {number, exponent}
  end

  # Output the number to a tuple - all the other transformations
  # are done on the tuple version split into its constituent
  # parts.

  @doc false
  def output_to_tuple(number, _meta, _backend, _options) when is_integer(number) do
    integer = :erlang.integer_to_list(number)
    {1, integer, [], 1, [?0]}
  end

  def output_to_tuple({coef, exponent}, _meta, _backend, _options) do
    {integer, fraction, sign} = Digits.to_tuple(coef)
    exponent_sign = if exponent >= 0, do: 1, else: -1
    integer = Enum.map(integer, &Kernel.+(&1, ?0))
    fraction = Enum.map(fraction, &Kernel.+(&1, ?0))
    exponent = if exponent == 0, do: [?0], else: Integer.to_charlist(abs(exponent))
    {sign, integer, fraction, exponent_sign, exponent}
  end

  # Remove all the leading zeros from an integer and add back what
  # is required for the format.

  @doc false
  def adjust_leading_zeros(
        {sign, integer, fraction, exponent_sign, exponent},
        %{integer_digits: integer_digits},
        _backend,
        _options
      ) do
    integer =
      if (count = integer_digits[:min] - length(integer)) > 0 do
        :lists.duplicate(count, ?0) ++ integer
      else
        integer
      end

    {sign, integer, fraction, exponent_sign, exponent}
  end

  @doc false
  def adjust_trailing_zeros(
        {sign, integer, fraction, exponent_sign, exponent},
        %{fractional_digits: fraction_digits},
        _backend,
        _options
      ) do
    fraction = do_trailing_zeros(fraction, fraction_digits[:min] - length(fraction))
    {sign, integer, fraction, exponent_sign, exponent}
  end

  defp do_trailing_zeros(fraction, count) when count <= 0 do
    fraction
  end

  defp do_trailing_zeros(fraction, count) do
    fraction ++ :lists.duplicate(count, ?0)
  end

  # Take the rightmost maximum digits only - this is a truncation from the
  # right.

  @doc false
  def set_max_integer_digits(number, %{integer_digits: %{max: 0}}, _backend, _options) do
    number
  end

  def set_max_integer_digits(
        {sign, integer, fraction, exponent_sign, exponent},
        %{integer_digits: %{max: max}},
        _backend,
        _options
      ) do
    integer = do_max_integer_digits(integer, length(integer) - max)
    {sign, integer, fraction, exponent_sign, exponent}
  end

  defp do_max_integer_digits(integer, over) when over <= 0 do
    integer
  end

  defp do_max_integer_digits(integer, over) do
    {_rest, integer} = Enum.split(integer, over)
    integer
  end

  # Insert the grouping placeholder in the right place in the number.
  # There may be one or two different groupings for the integer part
  # and one grouping for the fraction part.

  @doc false
  def apply_grouping(
        {sign, integer, [] = fraction, exponent_sign, exponent},
        %{grouping: groups},
        backend,
        %{locale: locale, minimum_grouping_digits: minimum_grouping_digits}
      ) do
    integer =
      do_grouping(
        integer,
        groups[:integer],
        length(integer),
        minimum_group_size(groups[:integer], minimum_grouping_digits, locale, backend),
        :reverse
      )

    {sign, integer, fraction, exponent_sign, exponent}
  end

  def apply_grouping(
        {sign, integer, fraction, exponent_sign, exponent},
        %{grouping: groups},
        backend,
        %{
          locale: locale,
          minimum_grouping_digits: minimum_grouping_digits
        }
      ) do
    integer =
      do_grouping(
        integer,
        groups[:integer],
        length(integer),
        minimum_group_size(groups[:integer], minimum_grouping_digits, locale, backend),
        :reverse
      )

    fraction =
      do_grouping(
        fraction,
        groups[:fraction],
        length(fraction),
        minimum_group_size(groups[:fraction], minimum_grouping_digits, locale, backend),
        :forward
      )

    {sign, integer, fraction, exponent_sign, exponent}
  end

  defp minimum_group_size(%{first: group_size}, 0, locale, backend) do
    Format.minimum_grouping_digits_for!(locale, backend) + group_size
  end

  defp minimum_group_size(%{first: group_size}, minimum_grouping_digits, _locale, _backend) do
    minimum_grouping_digits + group_size
  end

  # The actual grouping function.  Note there are two directions,
  # `:forward` and `:reverse`.  That's because we group from the decimal
  # placeholder outwards and there may be a final group that is less than
  # the grouping size.  For the fraction part the dangling part is at the
  # end (:forward direction) whereas for the integer part the dangling
  # group is at the beginning (:reverse direction)

  @group_separator Compiler.placeholder(:group)

  @doc false

  # No grouping if the length (number of digits) is less than the
  # minimum grouping size.
  def do_grouping(number, _, length, min_grouping, :reverse) when length < min_grouping do
    number
  end

  # No grouping when the length of the number is less than the group size
  def do_grouping(number, %{first: first, rest: first}, length, _, _) when length <= first do
    number
  end

  # The case when there is no grouping.
  def do_grouping(number, %{first: 0, rest: 0}, _, _, _) do
    number
  end

  # The common case of grouping in 3's
  def do_grouping(number, %{first: 3, rest: 3} = grouping, length, min, :reverse) do
    number
    |> Enum.reverse()
    |> do_grouping(grouping, length, min, :forward)
    |> Enum.reverse()
  end

  def do_grouping([a, b, c | rest], %{first: 3, rest: 3} = grouping, _length, min, :forward) do
    [a, b, c, @group_separator | do_grouping(rest, grouping, length(rest), min, :forward)]
  end

  # Only one group size
  def do_grouping(number, %{first: first, rest: first}, length, _, :forward) do
    split_point = div(length, first) * first
    {rest, last_group} = Enum.split(number, split_point)

    add_separator(rest, first, @group_separator)
    |> add_last_group(last_group, @group_separator)
  end

  def do_grouping(number, %{first: first, rest: first}, length, _, :reverse) do
    split_point = length - div(length, first) * first
    {first_group, rest} = Enum.split(number, split_point)

    add_separator(rest, first, @group_separator)
    |> add_first_group(first_group, @group_separator)
  end

  # The case when there are two different groupings. This applies only to
  # The integer part, it can never be true for the fraction part.
  def do_grouping(number, %{first: first, rest: rest}, length, _min_grouping, :reverse) do
    {others, first_group} = Enum.split(number, length - first)

    do_grouping(others, %{first: rest, rest: rest}, length(others), 1, :reverse)
    |> add_last_group(first_group, @group_separator)
  end

  @doc false
  def add_separator([], _every, _separator) do
    []
  end

  def add_separator(group, every, separator) do
    {_, [_ | rest]} =
      Enum.reduce(group, {1, []}, fn elem, {counter, list} ->
        list = [elem | list]
        list = if rem(counter, every) == 0, do: [separator | list], else: list
        {counter + 1, list}
      end)

    Enum.reverse(rest)
  end

  @doc false
  def add_first_group(groups, [], _separator) do
    groups
  end

  def add_first_group(groups, first, separator) do
    [first, separator, groups]
  end

  @doc false
  def add_last_group(groups, [], _separator) do
    groups
  end

  def add_last_group(groups, last, separator) do
    [groups, separator, last]
  end

  @decimal_separator Compiler.placeholder(:decimal)
  @exponent_separator Compiler.placeholder(:exponent)
  @exponent_sign Compiler.placeholder(:exponent_sign)
  @minus_placeholder Compiler.placeholder(:minus)

  @doc false
  def reassemble_number_string(
        {_sign, integer, fraction, exponent_sign, exponent},
        meta,
        _backend,
        options
      ) do
    decimal_separator = decimal_separator(options, @decimal_separator)
    integer = if integer == [], do: [~c"0"], else: integer
    fraction = if fraction == [], do: fraction, else: [decimal_separator, fraction]

    exponent_sign =
      cond do
        exponent_sign < 0 -> @minus_placeholder
        meta.exponent_sign -> @exponent_sign
        true -> ~c""
      end

    exponent =
      if meta.exponent_digits > 0 do
        digits =
          exponent
          |> List.to_string()
          |> String.pad_leading(meta.exponent_digits, "0")

        [@exponent_separator, exponent_sign, digits]
      else
        []
      end

    [integer, fraction, exponent]
    |> :erlang.iolist_to_binary()
  end

  # Now we can assemble the final format.  Based upon
  # whether the number is positive or negative (as indicated
  # by options[:sign]) we assemble the parts and transliterate
  # the currency sign, percent and permille characters.

  @doc false
  def assemble_format(number_string, meta, backend, options) do
    format = meta.format[options.pattern]
    number = meta.number

    formatted =
      assemble_parts(format, number_string, number, backend, meta, options)
      |> :erlang.iolist_to_binary()
      |> String.trim_trailing()

    formatted
  end

  defp assemble_parts(
         [{:format, _}, {:currency, _type} | rest],
         number_string,
         number,
         backend,
         meta,
         %{currency_spacing: spacing} = options
       )
       when not is_nil(spacing) do
    %{currency_symbol: symbol, wrapper: wrapper} = options
    before_spacing = spacing[:before_currency]
    before_currency_match? = before_currency_match?(number_string, symbol, before_spacing)
    symbol = maybe_wrap(symbol, :currency_symbol, wrapper)
    number_string = maybe_wrap(number_string, :number, wrapper)

    if before_currency_match? do
      [
        number_string,
        maybe_wrap(before_spacing[:insert_between], :currency_space, wrapper),
        symbol
        | assemble_parts(rest, number_string, number, backend, meta, options)
      ]
    else
      [
        number_string,
        symbol
        | assemble_parts(rest, number_string, number, backend, meta, options)
      ]
    end
  end

  defp assemble_parts(
         [{:currency, _type}, {:format, _} | rest],
         number_string,
         number,
         backend,
         meta,
         %{currency_spacing: spacing} = options
       )
       when not is_nil(spacing) do
    %{currency_symbol: symbol, wrapper: wrapper} = options
    after_spacing = spacing[:after_currency]
    after_currency_match? = after_currency_match?(number_string, symbol, after_spacing)
    symbol = maybe_wrap(symbol, :currency_symbol, wrapper)
    number_string = maybe_wrap(number_string, :number, wrapper)

    if after_currency_match? do
      [
        symbol,
        maybe_wrap(after_spacing[:insert_between], :currency_space, wrapper),
        number_string
        | assemble_parts(rest, number_string, number, backend, meta, options)
      ]
    else
      [
        symbol,
        number_string
        | assemble_parts(rest, number_string, number, backend, meta, options)
      ]
    end
  end

  defp assemble_parts([], _number_string, _number, _backend, _meta, _options) do
    []
  end

  @nbsp "\u200b"

  defp assemble_parts([{:currency, _type} | rest], number_string, number, backend, meta, options) do
    %{currency_symbol: symbol, wrapper: wrapper} = options

    if symbol == @nbsp do
      assemble_parts(rest, number_string, number, backend, meta, options)
    else
      symbol = maybe_wrap(symbol, :currency_symbol, wrapper)
      [symbol | assemble_parts(rest, number_string, number, backend, meta, options)]
    end
  end

  defp assemble_parts(
         [{:format, _} | rest],
         number_string,
         number,
         backend,
         meta,
         %{wrapper: wrapper} = options
       ) do
    [
      maybe_wrap(number_string, :number, wrapper)
      | assemble_parts(rest, number_string, number, backend, meta, options)
    ]
  end

  defp assemble_parts([{:pad, _} | rest], number_string, number, backend, meta, options) do
    [
      padding_string(meta, number_string)
      | assemble_parts(rest, number_string, number, backend, meta, options)
    ]
  end

  defp assemble_parts(
         [{:plus, _} | rest],
         number_string,
         number,
         backend,
         meta,
         %{wrapper: wrapper} = options
       ) do
    [
      maybe_wrap(options.symbols.plus_sign, :plus, wrapper)
      | assemble_parts(rest, number_string, number, backend, meta, options)
    ]
  end

  defp assemble_parts(
         [{:minus, _} | rest],
         number_string,
         number,
         backend,
         meta,
         %{wrapper: wrapper} = options
       ) do
    sign =
      if(number_string == "0", do: "", else: options.symbols.minus_sign)
      |> maybe_wrap(:minus, wrapper)

    [sign | assemble_parts(rest, number_string, number, backend, meta, options)]
  end

  defp assemble_parts(
         [{:percent, _} | rest],
         number_string,
         number,
         backend,
         meta,
         %{wrapper: wrapper} = options
       ) do
    [
      maybe_wrap(options.symbols.percent_sign, :percent, wrapper)
      | assemble_parts(rest, number_string, number, backend, meta, options)
    ]
  end

  defp assemble_parts(
         [{:permille, _} | rest],
         number_string,
         number,
         backend,
         meta,
         %{wrapper: wrapper} = options
       ) do
    [
      maybe_wrap(options.symbols.per_mille, :permille, wrapper)
      | assemble_parts(rest, number_string, number, backend, meta, options)
    ]
  end

  defp assemble_parts(
         [{:literal, literal} | rest],
         number_string,
         number,
         backend,
         meta,
         %{wrapper: wrapper} = options
       ) do
    [
      maybe_wrap(literal, :literal, wrapper)
      | assemble_parts(rest, number_string, number, backend, meta, options)
    ]
  end

  defp assemble_parts(
         [{:quote, _} | rest],
         number_string,
         number,
         backend,
         meta,
         %{wrapper: wrapper} = options
       ) do
    [
      maybe_wrap("'", :quote, wrapper)
      | assemble_parts(rest, number_string, number, backend, meta, options)
    ]
  end

  defp assemble_parts(
         [{:quoted_char, char} | rest],
         number_string,
         number,
         backend,
         meta,
         options
       ) do
    [char | assemble_parts(rest, number_string, number, backend, meta, options)]
  end

  # Invokes a wrapping function. It can return a Phoenix :safe
  # string or a string.
  defp maybe_wrap(string, _tag, nil), do: string

  defp maybe_wrap(string, tag, wrapper) do
    case wrapper.(string, tag) do
      {:safe, iodata} -> iodata
      iodata when is_list(iodata) -> iodata
      string when is_binary(string) -> string
    end
  end

  # Calculate the padding by subtracting the length of the number
  # string from the padding length.

  @doc false
  def padding_string(%{padding_length: 0}, _number_string) do
    @empty_string
  end

  # We can't make the assumption that the padding character is
  # an ascii character - it could be any grapheme so we can't use
  # binary pattern matching.
  def padding_string(meta, number_string) do
    pad_length = meta.padding_length - String.length(number_string)

    if pad_length > 0 do
      String.duplicate(meta.padding_char, pad_length)
    else
      @empty_string
    end
  end

  @doc false
  def transliterate(number_string, _meta, backend, options) do
    %{locale: locale, number_system: number_system} = options
    Cldr.Number.Transliterate.transliterate(number_string, locale, number_system, backend, options)
  end

  # When formatting a currency we need to adjust the number of fractional
  # digits to match the currency definition.  We also need to adjust the
  # rounding increment to match the currency definition. Note that here
  # we are just adjusting the meta data, not the number itself

  @doc false
  def adjust_fraction_for_currency(meta, nil, _currency_digits, _backend) do
    meta
  end

  def adjust_fraction_for_currency(meta, currency, _currency_digits, _backend)
      when is_digital_token(currency) do
    %{meta | fractional_digits: %{max: @max_token_fractional_digits, min: 0}}
  end

  def adjust_fraction_for_currency(meta, currency, :accounting, backend) do
    {:ok, currency} = Currency.currency_for_code(currency, backend)
    do_adjust_fraction(meta, currency.digits, currency.rounding)
  end

  def adjust_fraction_for_currency(meta, currency, :cash, backend) do
    {:ok, currency} = Currency.currency_for_code(currency, backend)
    do_adjust_fraction(meta, currency.cash_digits, currency.cash_rounding)
  end

  def adjust_fraction_for_currency(meta, currency, :iso, backend) do
    {:ok, currency} = Currency.currency_for_code(currency, backend)
    do_adjust_fraction(meta, currency.iso_digits, currency.iso_digits)
  end

  defp do_adjust_fraction(meta, digits, rounding) do
    rounding = power_of_10(-digits) * rounding
    %{meta | round_nearest: rounding}
  end

  # Functions to update metadata to reflect the
  # options passed at runtime.

  # If we round to sigificant digits then the format won't (usually)
  # have any fractional part specified and if we don't do something
  # then we're truncating the number - not really what is intended
  # for significant digits display.

  @doc false

  # For when there is no number format
  def adjust_fraction_for_significant_digits(%{significant_digits: nil} = meta, _number) do
    meta
  end

  # For no significant digits
  def adjust_fraction_for_significant_digits(
        %{significant_digits: %{max: 0, min: 0}} = meta,
        _number
      ) do
    meta
  end

  # No fractional digits for an integer
  def adjust_fraction_for_significant_digits(%{significant_digits: _} = meta, number)
      when is_integer(number) do
    meta
  end

  # Decimal version of an integer => exponent > 0
  def adjust_fraction_for_significant_digits(%{significant_digits: _} = meta, %Decimal{exp: exp})
      when exp >= 0 do
    meta
  end

  # For all float or Decimal fraction
  def adjust_fraction_for_significant_digits(%{significant_digits: _} = meta, _number) do
    %{meta | fractional_digits: %{max: 10, min: 1}}
  end

  # To allow overriding fractional digits
  # This causes rounding of the number

  @doc false
  def adjust_for_fractional_digits(meta, nil) do
    meta
  end

  def adjust_for_fractional_digits(meta, digits) do
    %{meta | fractional_digits: %{max: digits, min: digits}}
  end

  # To allow overriding fractional digits
  # This causes rounding of the number

  @doc false
  def adjust_for_integer_digits(meta, nil) do
    meta
  end

  def adjust_for_integer_digits(meta, digits) do
    integer_digits =
      meta
      |> Map.fetch!(:integer_digits)
      |> Map.put(:max, digits)

    %{meta | integer_digits: integer_digits}
  end

  # To allow overriding round nearest
  # which impacts the precision of the number
  # and is commonly required for currency
  # formatting

  @doc false
  def adjust_for_round_nearest(meta, nil) do
    meta
  end

  def adjust_for_round_nearest(meta, digits) do
    %{meta | round_nearest: digits}
  end

  @doc false
  def define_to_string(backend) do
    config = Module.get_attribute(backend, :config)

    compiled_artifacts =
      for format <- Cldr.Config.decimal_format_list(config) do
        case Compiler.compile(format) do
          {:ok, meta, formatting_pipeline} ->
            {format, meta, formatting_pipeline}

          {:error, message} ->
            raise Cldr.FormatCompileError, "#{message} compiling #{inspect(format)}"
        end
      end

    metadata =
      for {format, meta, _formatting_pipeline} <- compiled_artifacts do
        {format, meta}
      end
      |> Map.new()

    to_string_function =
      for {format, _meta, formatting_pipeline} <- compiled_artifacts do
        quote do
          def to_string(number_or_string, unquote(format) = format, options) do
            case number_or_string do
              string when is_binary(string) ->
                Decimal.do_to_string(string, metadata!(format), unquote(backend), options)

              %Elixir.Decimal{coef: coef} = number when coef in [:NaN, :inf] ->
                Decimal.do_to_string(number, metadata!(format), unquote(backend), options)

              number ->
                meta =
                  format
                  |> metadata!()
                  |> Decimal.update_meta(number, unquote(backend), options)

                backend = unquote(backend)
                unquote(formatting_pipeline)
            end
          end
        end
      end

    metadata_function =
      quote do
        @doc false
        def metadata(format) do
          case Map.fetch(unquote(Macro.escape(metadata)), format) do
            {:ok, meta} -> {:ok, meta}
            :error -> Compiler.format_to_metadata(format)
          end
        end

        def metadata!(format) do
          case metadata(format) do
            {:ok, meta} -> meta
            {:error, reason} -> raise Cldr.FormatCompileError, reason
          end
        end
      end

    quote do
      unquote(to_string_function)
      unquote(metadata_function)
    end
  end

  @currency_match_symbol "[\\P{S}]$"
  @currency_match_separator "[\\P{Z}]$"

  # The unicode set "[[:^S:]&[:^Z:]]" isn't a valid Regex for Elixir/Erlang
  # The following is a substitution
  defp before_currency_match?(
         number_string,
         symbol,
         %{currency_match: "[[:^S:]&[:^Z:]]"} = spacing
       ) do
    String.match?(number_string, Regex.compile!(spacing[:surrounding_match] <> "$", "u")) &&
      String.match?(symbol, ~r/#{@currency_match_symbol}/u) &&
      String.match?(symbol, ~r/#{@currency_match_separator}/u)
  end

  defp before_currency_match?(number_string, symbol, spacing) do
    String.match?(number_string, Regex.compile!(spacing[:surrounding_match] <> "$", "u")) &&
      String.match?(symbol, Regex.compile!("^" <> spacing[:currency_match], "u"))
  end

  # The unicode set "[[:^S:]&[:^Z:]]" isn't a valid Regex for Elixir/Erlang
  # The following is a substitution
  defp after_currency_match?(
         number_string,
         symbol,
         %{currency_match: "[[:^S:]&[:^Z:]]"} = spacing
       ) do
    String.match?(number_string, Regex.compile!("^" <> spacing[:surrounding_match], "u")) &&
      String.match?(symbol, ~r/#{@currency_match_symbol}/u) &&
      String.match?(symbol, ~r/#{@currency_match_separator}/u)
  end

  defp after_currency_match?(number_string, symbol, spacing) do
    String.match?(number_string, Regex.compile!("^" <> spacing[:surrounding_match], "u")) &&
      String.match?(symbol, Regex.compile!(spacing[:currency_match] <> "$", "u"))
  end

  defp decimal_separator(%{currency: %{decimal_separator: nil}}, default_decimal_separator) do
    default_decimal_separator
  end

  defp decimal_separator(%{currency: %{decimal_separator: separator}}, _default_decimal_separator) do
    separator
  end

  defp decimal_separator(_options, default_decimal_separator) do
    default_decimal_separator
  end
end
