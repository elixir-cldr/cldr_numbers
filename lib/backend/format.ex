defmodule Cldr.Number.Backend.Format do
  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    number_system = Module.concat(backend, Number.System)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config, number_system: number_system] do
      defmodule Number.Format do
        @moduledoc """
        Functions to manage the collection of number patterns defined in Cldr.

        Number patterns affect how numbers are interpreted in a localized context.
        Here are some examples, based on the French locale. The "." shows where the
        decimal point should go. The "," shows where the thousands separator should
        go. A "0" indicates zero-padding: if the number is too short, a zero (in the
        locale's numeric set) will go there. A "#" indicates no padding: if the
        number is too short, nothing goes there. A "¤" shows where the currency sign
        will go. The following illustrates the effects of different patterns for the
        French locale, with the number "1234.567". Notice how the pattern characters
        ',' and '.' are replaced by the characters appropriate for the locale.

        ## Number Pattern Examples

        | Pattern	      | Currency	      | Text        |
        | ------------- | :-------------: | ----------: |
        | #,##0.##	    | n/a	            | 1 234,57    |
        | #,##0.###	    | n/a	            | 1 234,567   |
        | ###0.#####	  | n/a	            | 1234,567    |
        | ###0.0000#	  | n/a	            | 1234,5670   |
        | 00000.0000	  | n/a	            | 01234,5670  |
        | #,##0.00 ¤	  | EUR	            | 1 234,57 €  |

        The number of # placeholder characters before the decimal do not matter,
        since no limit is placed on the maximum number of digits. There should,
        however, be at least one zero some place in the pattern. In currency formats,
        the number of digits after the decimal also do not matter, since the
        information in the supplemental data (see Supplemental Currency Data) is used
        to override the number of decimal places — and the rounding — according to
        the currency that is being formatted. That can be seen in the above chart,
        with the difference between Yen and Euro formatting.

        Details of the number formats are described in the
        [Unicode documentation](http://unicode.org/reports/tr35/tr35-numbers.html#Number_Format_Patterns)

        """

        alias Cldr.Number.System

        @doc """
        Returns the list of decimal formats in the configured locales including
        the list of locales configured for precompilation in `config.exs`.

        This function exists to allow the decimal formatter
        to precompile all the known formats at compile time.

        ## Example

            #=> #{inspect(__MODULE__)}.Format.decimal_format_list ["#", "#,##,##0%",
            "#,##,##0.###", "#,##,##0.00¤", "#,##,##0.00¤;(#,##,##0.00¤)",
            "#,##,##0 %", "#,##0%", "#,##0.###", "#,##0.00 ¤",
            "#,##0.00 ¤;(#,##0.00 ¤)", "#,##0.00¤", "#,##0.00¤;(#,##0.00¤)",
            "#,##0 %", "#0%", "#0.######", "#0.00 ¤", "#E0", "%#,##0", "% #,##0",
            "0", "0.000000E+000", "0000 M ¤", "0000¤", "000G ¤", "000K ¤", "000M ¤",
            "000T ¤", "000mM ¤", "000m ¤", "000 Bio'.' ¤", "000 Bln ¤", "000 Bn ¤",
            "000 B ¤", "000 E ¤", "000 K ¤", "000 MRD ¤", "000 Md ¤", "000 Mio'.' ¤",
            "000 Mio ¤", "000 Mld ¤", "000 Mln ¤", "000 Mn ¤", "000 Mrd'.' ¤",
            "000 Mrd ¤", "000 Mr ¤", "000 M ¤", "000 NT ¤", "000 N ¤", "000 Tn ¤",
            "000 Tr ¤", ...]

        """
        @format_list Cldr.Config.decimal_format_list(config)
        @spec decimal_format_list :: [Cldr.Number.Format.format, ...]
        def decimal_format_list do
          unquote(Macro.escape(@format_list))
        end

        @doc """
        Returns the list of decimal formats for a configured locale.

        ## Arguments

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`. The default
          is `Cldr.get_current_locale/0`

        This function exists to allow the decimal formatter to precompile all
        the known formats at compile time. Its use is not otherwise recommended.

        ## Example

            iex> #{inspect(__MODULE__)}.decimal_format_list_for("en")
            {:ok, ["#,##0%", "#,##0.###", "#E0", "0 billion", "0 million", "0 thousand",
             "0 trillion", "00 billion", "00 million", "00 thousand", "00 trillion",
             "000 billion", "000 million", "000 thousand", "000 trillion", "000B", "000K",
             "000M", "000T", "00B", "00K", "00M", "00T", "0B", "0K", "0M", "0T",
             "¤#,##0.00", "¤#,##0.00;(¤#,##0.00)", "¤000B", "¤000K", "¤000M",
             "¤000T", "¤00B", "¤00K", "¤00M", "¤00T", "¤0B", "¤0K", "¤0M", "¤0T"]}

        """
        @spec decimal_format_list_for(LanguageTag.t() | Locale.locale_name()) ::
                {:ok, [String.t(), ...]} | {:error, {Exception.t(), String.t()}}

        def decimal_format_list_for(locale \\ unquote(backend).get_current_locale())

        for locale_name <- Cldr.Config.known_locale_names(config) do
          decimal_formats = Cldr.Config.decimal_formats_for(locale_name)

          def decimal_format_list_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
            {:ok, unquote(Macro.escape(decimal_formats))}
          end
        end

        def decimal_format_list_for(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            decimal_format_list_for(locale)
          end
        end

        def decimal_format_list_for(locale) do
          {:error, Cldr.Locale.locale_error(locale)}
        end

        @doc """
        Returns the decimal formats defined for a given locale.

        ## Arguments

        * `locale` is any valid locale name returned by
          `#{inspect(backend)}.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by
          `#{inspect(backend)}.Locale.new!/2`. The default
          is `#{inspect(backend)}.get_current_locale/1`

        ## Returns

        * a list of decimal formats or

        * `{:error, {exception, message}}`

        """
        @spec all_formats_for(LanguageTag.t() | Cldr.Locale.locale_name()) ::
                {:ok, non_neg_integer} | {:error, {Exception.t(), String.t()}}

        def all_formats_for(locale \\ unquote(backend).get_current_locale())

        @doc """
        Returns the minimum grouping digits for a locale.

        ## Arguments

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by
          `#{inspect(backend)}.Locale.new!/1`. The default
          is `#{inspect(backend)}.get_current_locale/0`

        ## Returns

        * `{:ok, minumum_digits}` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> #{inspect(__MODULE__)}.Number.Format.minimum_grouping_digits_for("en")
            {:ok, 1}

        """
        @spec minimum_grouping_digits_for(LanguageTag.t() | Cldr.Locale.locale_name()) ::
                {:ok, non_neg_integer} | {:error, {Exception.t(), String.t()}}

        def minimum_grouping_digits_for(locale \\ unquote(backend).get_current_locale())

        for locale_name <- Cldr.Config.known_locale_names(config) do
          locale_data =
            locale_name
            |> Cldr.Config.get_locale()

          number_formats =
            locale_data
            |> Map.get(:number_formats)
            |> Enum.map(fn {type, format} -> {type, struct(Cldr.Number.Format, format)} end)
            |> Enum.into(%{})

          minimum_grouping_digits =
            locale_data
            |> Map.get(:minimum_grouping_digits)

          def all_formats_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
            {:ok, unquote(Macro.escape(number_formats))}
          end

          def minimum_grouping_digits_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
            {:ok, unquote(minimum_grouping_digits)}
          end
        end

        def all_formats_for(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            all_formats_for(locale)
          end
        end

        def minimum_grouping_digits_for(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            minimum_grouping_digits_for(locale)
          end
        end

        @doc """
        Returns the minium grouping digits for a locale.
        or raises on error.

        ## Arguments

        * `locale` is any valid locale name returned by
          `#{inspect(backend)}.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
          is `#{inspect(backend)}.get_current_locale/1`

        ## Returns

        * `minumum_digits` or

        * raises an exception

        ## Examples

            iex> #{inspect(__MODULE__)}.Number.Format.minimum_grouping_digits_for!("en")
            1

        """
        @spec minimum_grouping_digits_for!(LanguageTag.t() | Cldr.Locale.locale_name()) ::
                non_neg_integer | no_return()

        def minimum_grouping_digits_for!(locale) do
          case minimum_grouping_digits_for(locale) do
            {:ok, digits} -> digits
            {:error, {exception, reason}} -> raise exception, reason
          end
        end

        @doc """
        Returns the decimal formats defined for a given locale.

        ## Arguments

        * `locale` is any valid locale name returned by
          `#{inspect(backend)}.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by
          `#{inspect(backend)}.Locale.new!/2`. The default
          is `#{inspect(backend)}.get_current_locale/1`

        ## Returns

        * a list of decimal formats ot

        * raises an exception

        See `#{inspect(__MODULE__)}.Number.Format.all_formats_for/1` for further information.

        """
        @spec all_formats_for!(LanguageTag.t() | Cldr.Locale.locale_name()) ::
                non_neg_integer | no_return()

        def all_formats_for!(locale \\ unquote(backend).get_current_locale()) do
          case all_formats_for(locale) do
            {:ok, formats} -> formats
            {:error, {exception, message}} -> raise exception, message
          end
        end

        @doc """
        Return the predfined formats for a given `locale` and `number_system`.

        ## Arguments

        * `locale` is any valid locale name returned by
          `#{inspect(backend)}.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`.
          The default is `#{inspect(backend)}.get_current_locale/0`

        * `number_system` is any valid number system or number system type returned
          by `#{inspect(backend)}.Number.System.number_systems_for/1`

        ## Example

            #{inspect(__MODULE__)}.formats_for "fr", :native
            #=> %Cldr.Number.Format{
              accounting: "#,##0.00 ¤;(#,##0.00 ¤)",
              currency: "#,##0.00 ¤",
              percent: "#,##0 %",
              scientific: "#E0",
              standard: "#,##0.###"
              currency_short: [{"1000", [one: "0 k ¤", other: "0 k ¤"]},
               {"10000", [one: "00 k ¤", other: "00 k ¤"]},
               {"100000", [one: "000 k ¤", other: "000 k ¤"]},
               {"1000000", [one: "0 M ¤", other: "0 M ¤"]},
               {"10000000", [one: "00 M ¤", other: "00 M ¤"]},
               {"100000000", [one: "000 M ¤", other: "000 M ¤"]},
               {"1000000000", [one: "0 Md ¤", other: "0 Md ¤"]},
               {"10000000000", [one: "00 Md ¤", other: "00 Md ¤"]},
               {"100000000000", [one: "000 Md ¤", other: "000 Md ¤"]},
               {"1000000000000", [one: "0 Bn ¤", other: "0 Bn ¤"]},
               {"10000000000000", [one: "00 Bn ¤", other: "00 Bn ¤"]},
               {"100000000000000", [one: "000 Bn ¤", other: "000 Bn ¤"]}],
               ...
              }

        """
        @spec formats_for(LanguageTag.t() | binary(), atom | String.t()) :: Map.t()
        def formats_for(%LanguageTag{} = locale, number_system) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale),
               {:ok, system_name} <- System.system_name_from(number_system, locale, unquote(backend)),
               {:ok, formats} <- all_formats_for(locale) do
            {:ok, Map.get(formats, system_name)}
          end
        end

        def formats_for(locale_name, number_system) when is_binary(locale_name) do
          with {:ok, locale} <- unquote(backend).validate_locale(locale_name) do
            formats_for(locale, number_system)
          end
        end
      end
    end
  end
end