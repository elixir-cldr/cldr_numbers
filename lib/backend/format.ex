defmodule Cldr.Number.Backend.Format do
  def define_number_module(config) do
    module = inspect(__MODULE__)
    backend = config.backend
    config = Macro.escape(config)

    quote location: :keep, bind_quoted: [module: module, backend: backend, config: config] do
      defmodule Format do
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
        format_list =
          config
          |> Cldr.Config.known_locale_names
          |> Enum.map(&Cldr.Config.decimal_formats_for/1)
          |> Kernel.++(Cldr.Config.get_precompile_number_formats())
          |> List.flatten()
          |> Enum.uniq()
          |> Enum.reject(&is_nil/1)
          |> Enum.sort()

        @spec decimal_format_list :: [format, ...]
        def decimal_format_list do
          unquote(Macro.escape(format_list))
        end

        @doc """
        Returns the list of decimal formats for a configured locale.

        ## Options

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`. The default
          is `Cldr.get_current_locale/0`

        This function exists to allow the decimal formatter to precompile all
        the known formats at compile time. Its use is not otherwise recommended.

        ## Example

            iex> Cldr.Number.Format.decimal_format_list_for("en")
            {:ok, ["#,##0%", "#,##0.###", "#E0", "0 billion", "0 million", "0 thousand",
             "0 trillion", "00 billion", "00 million", "00 thousand", "00 trillion",
             "000 billion", "000 million", "000 thousand", "000 trillion", "000B", "000K",
             "000M", "000T", "00B", "00K", "00M", "00T", "0B", "0K", "0M", "0T",
             "¤#,##0.00", "¤#,##0.00;(¤#,##0.00)", "¤000B", "¤000K", "¤000M",
             "¤000T", "¤00B", "¤00K", "¤00M", "¤00T", "¤0B", "¤0K", "¤0M", "¤0T"]}

        """
        @spec decimal_format_list_for(LanguageTag.t() | Locale.locale_name()) ::
                {:ok, [String.t(), ...]} | {:error, {Exception.t(), String.t()}}

        def decimal_format_list_for(locale \\ Cldr.get_current_locale())

        for locale_name <- Cldr.Config.known_locale_names() do
          decimal_formats = Cldr.Config.decimal_formats_for(locale_name)

          def decimal_format_list_for(%LanguageTag{cldr_locale_name: unquote(locale_name)}) do
            {:ok, unquote(Macro.escape(decimal_formats))}
          end
        end

        def decimal_format_list_for(locale_name) when is_binary(locale_name) do
          with {:ok, locale} <- Cldr.validate_locale(locale_name) do
            decimal_format_list_for(locale)
          end
        end

        def decimal_format_list_for(locale) do
          {:error, Locale.locale_error(locale)}
        end

        @doc """
        Returns the minium grouping digits for a locale.

        ## Options

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/0`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/1`. The default
          is `Cldr.get_current_locale/0`

        ## Returns

        * `{:ok, minumum_digits}` or

        * `{:error, {exception, message}}`

        ## Examples

            iex> Cldr.Number.Format.minimum_grouping_digits_for("en")
            {:ok, 1}

        """
        @spec minimum_grouping_digits_for(LanguageTag.t()) ::
                {:ok, non_neg_integer} | {:error, {Exception.t(), String.t()}}

        def minimum_grouping_digits_for(locale \\ Cldr.get_current_locale())

        for locale_name <- Cldr.Config.known_locale_names() do
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

        @doc """
        Returns the decimal formats defined for a given locale.

        ## Arguments

        * `locale` is any valid locale name returned by `Cldr.known_locale_names/1`
          or a `Cldr.LanguageTag` struct returned by `Cldr.Locale.new!/2`. The default
          is `Cldr.get_current_locale/1`

        ## Returns

        * a list of decimal formats ot

        * raises an exception

        See `Cldr.Number.Format.all_formats_for/1` for further information.

        """
        def all_formats_for!(locale) do
          case all_formats_for(locale) do
            {:ok, formats} -> formats
            {:error, {exception, message}} -> raise exception, message
          end
        end
      end
    end
  end
end