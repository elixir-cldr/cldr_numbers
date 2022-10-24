# Changelog

## Cldr_Numbers v2.28.0

This is the changelog for Cldr v2.28.0 released on October 24th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

* Encapsulates [CLDR 42](https://cldr.unicode.org/index/downloads/cldr-42) data. Unless otherwise noted, all the changes are reflected in `ex_cldr` libraries and functions.

## Cldr_Numbers v2.27.3

This is the changelog for Cldr v2.27.3 released on October 8th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* `Cldr.Number.to_string/3` with `format: :narrow` and `:currency` set will use the currency's narrow symbol.

* Apply currency spacing for short formats (previously not being applied)

## Cldr_Numbers v2.27.2

This is the changelog for Cldr v2.27.2 released on July 21st, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix `:short` formatting of decimal numbers with specified fractional digits. Thanks to @glennr for the report. Closes #32.

## Cldr_Numbers v2.27.1

This is the changelog for Cldr v2.27.1 released on July 20th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix `:short` formatting of negative numbers. Thanks to @glennr for the report. Closes #30.

## Cldr_Numbers v2.27.0

This is the changelog for Cldr v2.27.0 released on May 14th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Add support for formatting numbers representing [ISO 24165](https://www.iso.org/standard/80601.html) Digital Tokens (aka crypto currencies). The behaviour follows that for currency formatting. Given that the [digital token registry](https://dtif.org) does not contain fraction precision data or pluralised or localised token names, the formatting of digital tokens amounts is not localized beyond formatting the number itself.

## Cldr_Numbers v2.26.0

This is the changelog for Cldr v2.26.0 released on April 6th, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Update [CLDR](https://cldr.unicode.org) to [release 41](https://cldr.unicode.org/index/downloads/cldr-41) in [ex_cldr version 2.28.0](https://hex.pm/packages/ex_cldr/2.28.0)

## Cldr_Numbers v2.25.2

This is the changelog for Cldr v2.25.1 released on March 2nd, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fixes formatting of `Decimal` `Inf` and `NaN` numbers. Thanks to @sh41 for the report. Closes #26.

## Cldr_Numbers v2.25.1

This is the changelog for Cldr v2.25.1 released on February 22nd, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Remove compiler warnings on Elixir 1.11. Thanks to @koszta for the report. Fixes #24.

* Remove spurious `@dialyzer` directives that are no longer required (because we understand dialyzer a little bit more now).

## Cldr_Numbers v2.25.0

This is the changelog for Cldr v2.25.0 released on February 21st, 2022.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Updates to [ex_cldr version 2.26.0](https://hex.pm/packages/ex_cldr/2.26.0) which uses atoms for locale names and rbnf locale names. This is consistent with out elements of `t:Cldr.LanguageTag` where atoms are used where the cardinality of the data is fixed and relatively small and strings where the data is free format.

## Cldr_Numbers v2.24.0

This is the changelog for Cldr v2.24.0 released on December 30th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Allowed limited forms of format composition. For example, composing a `:long` format with a `:currency` format:
```elixir
iex> Cldr.Number.to_string!(100_000_000, format: :long) |> Cldr.Number.to_string(format: :currency)
{:ok, "$100 million"}
```

* Add format `:currency_long_with_symbol` which is a composite of `:currency_long` and the locales standard currency format. This supports formatting of of numbers like "$100 million" in the example above.

## Cldr_Numbers v2.23.3

This is the changelog for Cldr v2.23.3 released on December 14th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fixes short formatting for decimal numbers. Thanks to @datrader for the report.  Closes #135 on [ex_money](https://github.com/kipcole9/ex_money).

## Cldr_Numbers v2.23.2

This is the changelog for Cldr v2.23.2 released on December 3rd, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fixes `Cldr.Number.Parser.resolve_currencies/1` when the argument is whitespace only. Thanks to @datrader for the report.

## Cldr_Numbers v2.23.1

This is the changelog for Cldr v2.23.1 released on December 1st, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Replace `use Mix.Config` with `import Config` in config files

* Fix typespec for `<backend>.Cldr.Number.Transliterate.transliterate_digits/3`

## Cldr_Numbers v2.23.0

This is the changelog for Cldr v2.23.0 released on October 27th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Updates to support [CLDR release 40](https://cldr.unicode.org/index/downloads/cldr-40) via [ex_cldr version 2.24](https://hex.pm/packages/ex_cldr/2.24.0)

* Adds `Cldr.Rbnf.rule_names_for_locale/1` to return the available RBNF rule names for a given locale.

### Bug Fixes

* Arbitrary RBNF rule lookup falls back to the root locale (called "und") when checking if a rule is available. Thanks to @maennchen for the report. Closes #22.

* Fixes performance issue when calling `Cldr.Number.to_string/3` with an arbitrary RBNF rule name. Previously these formats would mistakenly read the raw json file for a locale incurring a significant performance penaly. Performance is now 100x faster as expected. Thanks to @maennchen for the bug report. Closes #21.

### Deprecations

* Don't call deprecated `Cldr.Config.known_locale_names/1`, call `Cldr.Locale.Loader.known_locale_names/1` instead.

* Don't call deprecated `Cldr.Config.get_locale/2`, use `Cldr.Locale.Loader.get_locale/2` instead.

## Cldr_Numbers v2.23.0-rc.4

This is the changelog for Cldr v2.23.0-rc.4 released on October 26th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Arbitrary RBNF rule lookup falls back to the root locale (called "und") when checking if a rule is available. Thanks to @maennchen for the report. Closes #22.

## Cldr_Numbers v2.23.0-rc.3

This is the changelog for Cldr v2.23.0-rc.3 released on October 25th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Deprecations

* Don't call deprecated `Cldr.Config.known_locale_names/1`, call `Cldr.Locale.Loader.known_locale_names/1` instead.

## Cldr_Numbers v2.23.0-rc.2

This is the changelog for Cldr v2.23.0-rc.2 released on October 24th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Don't call deprecated `Cldr.Config.get_locale/2`, use `Cldr.Locale.Loader.get_locale/2` instead.

## Cldr_Numbers v2.23.0-rc.1

This is the changelog for Cldr v2.23.0-rc.1 released on October 24th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Adds `Cldr.Rbnf.rule_names_for_locale/1` to return the available RBNF rule names for a given locale.

### Bug Fixes

* Fixes performance issue when calling `Cldr.Number.to_string/3` with an arbitrary RBNF rule name. Previously these formats would mistakenly read the raw json file for a locale incurring a significant performance penaly. Performance is now 100x faster as expected. Thanks to @maennchen for the bug report. Closes #21.

## Cldr_Numbers v2.23.0-rc.0

This is the changelog for Cldr v2.23.0-rc.0 released on October 3rd, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Updates to support [CLDR release 40](https://cldr.unicode.org/index/downloads/cldr-40)

## Cldr_Numbers v2.22.1

This is the changelog for Cldr v2.22.1 released on September 13th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Return the remainder strings with casing preserved when resolving currencies and pers in `Cldr.Numbers.Parser`.

## Cldr_Numbers v2.22.0

This is the changelog for Cldr v2.22.0 released on August 22nd, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* `Cldr.Number.Parser.resolve_currencies/2` and `Cldr.Number.Parser.resolve_per/2` only perform replacements if the the found string is not adjacent to an alphabetic character.

* `Cldr.Number.Parser.resolve/2` and `Cldr.Number.Parser.find_and_replace/2` are made public functions.

* Add `resolve_pers/2` and `resolve_per/2` to the `MyApp.Number` module.

## Cldr_Numbers v2.21.0

This is the changelog for Cldr v2.21.0 released on August 18th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Add `Cldr.Number.Parser.resolve_pers/2` which will tokenize percent and permille symbols into `:percent` and `:permille`. This is similar to the `Cldr.Number.Parser.resolve_currencies/2` function but for percent and permille symbols. An example is:

```elixir
iex> Cldr.Number.Parser.scan("100%")
...> |> Cldr.Number.Parser.resolve_pers()
[100, :percent]
```

## Cldr_Numbers v2.20.0

This is the changelog for Cldr v2.20.0 released on August 17th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Improve number parsing with `Cldr.Number.Parser.scan/2` when the string has lists of numbers separated by commas.  Thanks to @DaTrader for the report. Closes #19.

### Enhancements

* Add support for custom currency symbols. This extends the use of the `:currency_symbol` option. In previously releases this option was required to be `:standard` or `:iso`. Now the value can also be `:narrow`, `:symbol` or a string which will be used as the currency symbol.  From the documentation for `Cldr.Number.to_string/3`:

  * `currency_symbol`: Allows overriding a currency symbol. The alternatives
    are:
    * `:iso` the ISO currency code will be used instead of the default
      currency symbol.
    * `:narrow` uses the narrow symbol defined for the locale. The same
      narrow symbol can be defined for more than one currency and therefore this
      should be used with care. If no narrow symbol is defined, the standard
      symbol is used.
    * `:symbol` uses the standard symbol defined in CLDR. A symbol is unique
      for each currency and can be safely used.
    * "string" uses `string` as the currency symbol
    * `:standard` (the default and recommended) uses the CLDR-defined symbol
      based upon the currency format for the locale.

## Cldr_Numbers v2.19.0

This is the changelog for Cldr v2.19.0 released on July 1st, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Updated to [ex_cldr version 2.23.0](https://hex.pm/packages/ex_cldr/2.23.0) which changes the names of some of the field in the "-u-" extension to match the CLDR canonical name. In particular the field name `number_system` changes to `numbers`.

## Cldr_Numbers v2.18.4

This is the changelog for Cldr v2.18.4 released on June 17th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Allow `t:Cldr.Currency` as a `:currency` option in `Cldr.Number.to_string/2`. Thanks to @jeroenvisser101 for the PR.

## Cldr_Numbers v2.18.3

This is the changelog for Cldr v2.18.3 released on June 12th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Breaking Change

* There is a minor breaking change in the error return from `Cldr.Number.Parser.parse/2`. Previously the error return was `{:error, string}`. It is now more consistent with the rest of `ex_cldr` and returns `{:error, {exception, message}}`

### Bug Fixes

* Fix `Cldr.Number.Parser.parse/2` for numbers that are in non-latin scripts (like Thai, Arabic, ...). There are 66 known number systems that have decimal digits as of CLDR39.

## Cldr_Numbers v2.18.2

This is the changelog for Cldr v2.18.2 released on June 11th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix `Cldr.Number.Parser.scan/2` to correctly parse numbers like `1kg`

## Cldr_Numbers v2.18.1

This is the changelog for Cldr v2.18.1 released on June 8th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

Thanks to @alaadahmed for the collaboration to fix two bugs in rules based number formatting.

* Fixes RBNF formatting options setting for `:spellout_ordinal`

* Allows any defined RNBF rule for a locale to be invoked as the `:format` option to `Cldr.Number.to_string/3`.

## Cldr_Numbers v2.18.0

This is the changelog for Cldr v2.18.0 released on May 8th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fixes short and long number formatting.

* Fixes formatting whent the format string consists only of digits. Previously this would erroneously set both the maximum and minimum integer digits. Now it only sets the minimum integer digits.

### Enhancements

* Add option `:maximum_integer_digits` as an option to `Cldr.Number.to_string/2`

## Cldr_Numbers v2.17.0

This is the changelog for Cldr v2.17.0 released on April 8th, 2021.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Updated to require [ex_cldr version 2.20](https://hex.pm/packages/ex_cldr/2.20.0) which includes [CLDR 39](http://cldr.unicode.org/index/downloads/cldr-39) data.

## Cldr_Numbers v2.16.1

This is the changelog for Cldr v2.16.1 released on November 8th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix bug in `Cldr.Number.System.number_system_from/1` to correctly allow a binary language tag without a backend parameter (which will then default to `Cldr.default_backend!/0`)

## Cldr_Numbers v2.16.0

This is the changelog for Cldr v2.16.0 released on November 1st, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Support [CLDR 38](http://cldr.unicode.org/index/downloads/cldr-38)

* Add `Cldr.Number.Formatter.Short.short_format_exponent/2` to support compact number pluralization that is added to CLDR 38 (for the "fr" locale only in this release)

## Cldr_Numbers v2.15.4

This is the changelog for Cldr v2.15.4 released on Septmber 26th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Use `Cldr.default_backend!/1` when available since `Cldr.default_backend/0` is deprecated as of `ex_cldr` version `2.18.0`.

### Bug Fixes

* Use `Cldr.Decimal.compare/2` which works consistently with `Decimal` `1.x` and `2.x`

* Apply compile-time detection of `Decimal` version in order to know the correct return type of `Decimal.parse/1` which differs between `1.x` and `2.x`

## Cldr_Numbers v2.15.3

This is the changelog for Cldr v2.15.3 released on September 5th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix documentation referencing `Cldr.known_locale_names/10` to correctly reference `Cldr.known_locale_names/0`.

## Cldr_Numbers v2.15.2

This is the changelog for Cldr v2.15.2 released on August 30th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Removes dialyzer warning when running on Elixir 1.11.  Uses `Logger.warning/2` not `Logger.warn/2` in this case and uses an anonymous function not a string so that dialyzer is happy.

## Cldr_Numbers v2.15.1

This is the changelog for Cldr v2.15.1 released on June 23rd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fixes two number parsing bugs:

  1. A bug whereby decimal and separator symbols would be impacted in non-number strings when using `MyApp.Cldr.Number.scan/2`
  2. A bug whereby numbers using various localised symbols would not be recognised

* Fix formatter pipeline generation which was including the `round nearest` pipeline stage even when not required.  Thanks to @jeroenvisser101 for the collaboration. Fixes #14.

## Cldr_Numbers v2.15.0

This is the changelog for Cldr v2.15.0 released on June 13th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Support binary locale name as an argument to `Cldr.Number.System.number_system_from_locale/2`

* Add `number_system_from_locale/1` to backend modules

## Cldr_Numbers v2.14.0

This is the changelog for Cldr v2.14.0 released on May 27th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Add `Cldr.Number.Parser.parse/2` to parse numbers in a locale-aware manner

* Add `Cldr.Number.Parser.scan/2` to parse a string into a list of string and numbers

* Add `Cldr.Number.Parser.resolve_currencies/2` to match strings to currency codes in a list

* Add `Cldr.Number.Parser.resolve_currency/2` to match a string to a currency code

## Cldr_Numbers v2.13.2

This is the changelog for Cldr v2.13.2 released on May 16th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix regression and allow `:percent` formats in `Cldr.Number.to_string/3`. Thanks to @maennchen. Fixes #13.

## Cldr_Numbers v2.13.1

This is the changelog for Cldr v2.13.1 released on May 14th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix regression and allow `:fractional_digits` to be `0`. Thanks to @coladarci. Fixes #12.

## Cldr_Numbers v2.13.0

This is the changelog for Cldr v2.13.0 released on May 2nd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Breaking change

* In previous releases, requesting a currency format in `Number.to_string/3` without specifying an option `:currency` would return an error. In this release, a currency is derived from the locale (either the `:locale` parameter or from `backend.get_locale()`). The affected currency formats are `:currency`, `:accounting`, `:currency_long` and `:currency_short`

### Enhancements

* `Cldr.Number.to_string/2` now detects the number system from any supplied locale. If provided, the option `:number_system` takes precedence over the number system derived from a locale.

* Add `:round_nearest` formatting option for `Cldr.Number.to_string/3`. If provided, this option overrides the value defined by the `:format` option.

* Refines number system detection. The order of precedence is:

	* The `:number_system` option if provided

	* The `:number_system` from the locale if provided

	* The `:number_system` from the current locale for the supplied backend. This locale is retrieved with `backend.get_locale()`

## Cldr_Numbers v2.12.1

This is the changelog for Cldr v2.12.1 released on March 2nd, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Use the RBNF format `spellout_numbering` instead of `spellout_cardinal` for the `Cldr.Number.to_string/3` option `format: :spellout` since `spellout_numbering` has a larger locale coverage of RBNF formats.

## Cldr_Numbers v2.12.0

This is the changelog for Cldr v2.12.0 released on January 21st, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Updates version requirement for `cldr_utils` in order to support versions of `decimal` from `1.6` up to `2.0`.

### Bug fixes

* Fixes an incorrect typespec on `Cldr.Number.Format.format_from_locale_or_options/1` that was causing a dialyzer warning

## Cldr_Numbers v2.11.0

This is the changelog for Cldr v2.11.0 released on January 19th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Uses the number system defined by the locale if it is specified.  The number system is defined as part of the [U extension](https://unicode.org/reports/tr35/#u_Extension). The order of precedence is:

  * :default if no option is provided to `MyApp.Cldr.Number.to_string/2` and no number system is defined in the locale

  * The option `:number_system` if it is provided to `MyApp.Cldr.Number.to_string/2`

  * The locale's `number_system` if it is defined and the option `:number_system` to `MyApp.Cldr.Number.to_string/2` is *not* provided

Examples:
```
 # Locale defines a number system and no option :number_system is provided
 iex> TestBackend.Cldr.Number.to_string(1234, locale: "th-u-nu-thai")
 {:ok, "๑,๒๓๔"}

 # Locale defines a number system but an option :number_system is also provided which
 # take precedence
 iex> MyApp.Cldr.Number.to_string 1234, locale: "th-u-nu-latn", number_system: :thai
 {:ok, "๑,๒๓๔"}

 # A number system is defined in the locale but it is not supported by the
 # locale
 iex> MyApp.Cldr.Number.to_string 1234, locale: "en-AU-u-nu-thai"
 {:error,
  {Cldr.UnknownNumberSystemError,
   "The number system :thai is unknown for the locale named \"en\". Valid number systems are %{default: :latn, native: :latn}"}}
```

* Uses the currency code defined by the locale if it is specified and the number format requested is `:currency`. The currency code is defined as part of the [U extension](https://unicode.org/reports/tr35/#u_Extension). The order of precedence is:

  * The option `:currency` if it is provided to `MyApp.Cldr.Number.to_string/2`

  * The locale's `currency code` if it is defined and the option `:currency` to `MyApp.Cldr.Number.to_string/2` is *not* provided

Examples:
```
 # Use the currency code :AUD specified in the locale
 iex> MyApp.Cldr.Number.to_string 1234, locale: "en-AU-u-cu-aud", format: :currency
 {:ok, "A$1,234.00"}

 # Use the currency code :USD provided as an option in precedence over the currency code
 # defined by the locale
 iex> MyApp.Cldr.Number.to_string 1234, locale: "en-AU-u-cu-aud", format: :currency, currency: :USD
 {:ok, "$1,234.00"}
```

* Uses the currency format defined by the locale if it is specified and the number format requested is `:currency` or `:accounting`. The currency format is defined as part of the [U extension](https://unicode.org/reports/tr35/#u_Extension). The order of precedence is:

  * The locale's `currency format` if it is defined and the option `:format` to `MyApp.Cldr.Number.to_string/2` is either `:currency` or `:accounting`. Therefore the locales currency format takes precedence over the `:format` argument but only if `:format` is a currency format.

  * The option `:format` in every other case

Examples:
```
 # Using in the locale currency format - just happens to be the same as the format option
 iex> MyApp.Cldr.Number.to_string -1234, locale: "en-AU-u-cu-aud-cf-standard", format: :currency
 {:ok, "A$-1,234.00"}

 # The locale format takes precedence over the format option
 iex> MyApp.Cldr.Number.to_string -1234, locale: "en-AU-u-cu-aud-cf-standard", format: :accounting
 {:ok, "A$-1,234.00"}

 iex> MyApp.Cldr.Number.to_string -1234, locale: "en-AU-u-cu-aud-cf-account", format: :accounting
 {:ok, "(A$1,234.00)"}

 iex> MyApp.Cldr.Number.to_string -1234, locale: "en-AU-u-cu-aud-cf-account", format: :currency
 {:ok, "(A$1,234.00)"}
```

## Cldr_Numbers v2.10.0

This is the changelog for Cldr v2.10.0 released on January 15th, 2020.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fixes formatting of negative percentages. Actually fixes an issue where the default negative format would be incorrect in many cases. Thanks to @maennchen. Closes #11.

### Enhancements

* Optionally logs a warning if compiling a number format at runtime. The warning is emitted only once for each format to reduce log clutter. The log warning is emitted if the backend configuration key `:supress_warnings` is set to `false` (this is the default value). The `warn_once` mechanism depends on the availability of the `:persistent_term` module which is only available from OTP 21.2 onwards. On earlier releases of OTP no warning will be emitted.

## Cldr_Numbers v2.9.0

This is the changelog for Cldr v2.9.0 released on October 20th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Adds option `:currency_symbol` to `Cldr.Number.to_string/2`. This option, when set to `:iso` changes a currency format to force using the ISO currency code instead of the native currency symbol.

## Cldr_Numbers v2.8.0

This is the changelog for Cldr v2.8.0 released on October 10th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Update [ex_cldr](https://github.com/elixir-cldr/cldr) to version `2.11.0` which encapsulates [CLDR](https://cldr.unicode.org) version `36.0.0` data.

## Cldr_Numbers v2.7.2

This is the changelog for Cldr v2.7.2 released on September 7th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Call `Keyword.get_lazy/3` when accessing `Cldr.default_locale/0` to avoid exceptions when no default backend is configured but an optional `:backend` has been passed.

## Cldr_Numbers v2.7.1

This is the changelog for Cldr v2.7.1 released on August 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix `@spec` for `Cldr.Number.to_string/3` and `Cldr.Number.to_string!/3`

## Cldr_Numbers v2.7.0

This is the changelog for Cldr v2.7.0 released on August 21st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* An option `:backend` can be passed to `Cldr.Number.to_string/3` and it will be used if being called as `Cldr.Number.to_string/2`.  This means that for a call like `Cldr.Number.to_string(number, backend, options)` which has an option `:backend`, the call can be replaced with `Cldr.Number.to_string(number, options)`.

## Cldr_Numbers v2.6.4

This is the changelog for Cldr v2.6.4 released on June 16th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix the default value for the `backend` parameter for `Cldr.Number.to_string/3`

* Allow `Cldr.Number.to_string/3` to be called as `Cldr.Number.to_string <number>, <options>` as long as there is a default backend configured in `config.exs`.

## Cldr_Numbers v2.6.3

This is the changelog for Cldr v2.6.3 released on June 15th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Correctly interpret the special short format `0` to mean "format as a normal decimal or currency number". Thanks to @epilgrim.  Closes #10

## Cldr_Numbers v2.6.2

This is the changelog for Cldr v2.6.2 released on June 12th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Don't transliterate in `Cldr.Number.Transliterate.transliterate_digits/3` if `from` and `to` number systems are the same.

## Cldr_Numbers v2.6.1

This is the changelog for Cldr v2.6.1 released on June 2nd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Ensure `Cldr.Number.to_string/3` doesn't transliterate is the number systems are compatible for a given locale.  Basically, if the local and number system don't require transliteration from `0..9` to another script (like indian, arabic, ...) then we don't do it.  This improves performance by about 10% for this common case.

## Cldr_Numbers v2.6.0

This is the changelog for Cldr v2.6.0 released on March 28th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Updates to [CLDR version 35.0.0](http://cldr.unicode.org/index/downloads/cldr-35) released on March 27th 2019.

## Cldr_Numbers v2.5.0

This is the changelog for Cldr v2.5.0 released on March 23rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Supports `Cldr.default_backend()` as a default for a backend on functions in `Cldr.Number`

## Cldr_Numbers v2.4.4

This is the changelog for Cldr v2.4.4 released on March 21st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Rbnf.Ordinal and Rbnf.Spellout now respect the optional generation of @moduledocs in a backend

## Cldr_Numbers v2.4.3

This is the changelog for Cldr v2.4.3 released on March 20th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Bug Fixes

* Fix dialyzer warnings

## Cldr_Numbers v2.4.2

This is the changelog for Cldr v2.4.2 released on March 15th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

### Enhancements

* Makes generation of documentation for backend modules optional.  This is implemented by the `:generate_docs` option to the backend configuration.  The default is `true`. For example:

```
defmodule MyApp.Cldr do
  use Cldr,
    default_locale: "en-001",
    locales: ["en", "ja"],
    gettext: MyApp.Gettext,
    generate_docs: false
end
```
## Cldr_Numbers v2.4.1

This is the changelog for Cldr v2.4.1 released on March 7th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

## Bug Fixes

* Fix fractional grouping. Previously when there was no grouping, the group size was being set to the number of fractional digits.

* Fix scientific precision. Previously the mantissa was not being rounded because the prioritisation of significant digits over exponent digits was not being correctly reconciled.

* Fix formatting precision of an exponent. A format of `0E00` will now format the exponent with two digits.

* Fix o silence dialyzer warnings

## Cldr_Numbers v2.4.0

This is the changelog for Cldr v2.4.0 released on March 4th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

## Enhancements

* Adds `Cldr.Number.Format.default_grouping_for/2` to return the default grouping of digits for a locale. This is useful for external number formats like [ex_cldr_print](https://github.com/kipcole9/cldr_print).

## Cldr_Numbers v2.3.0

This is the changelog for Cldr v2.3.0 released on March 1st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

## Enhancements

* Opens up the formatting pipeline for use by other formatting systems like `printf`. This is implemented by the introduction of `Cldr.Number.Format.Meta` to create the abstract metadata struct.  This struct is used for `Cldr.Number.to_string/3` and is now available for use by other libraries. The function `Cldr.Number.Formatter.Decimal.to_string/3` is the primary function that should be used by other libraries.

## Cldr_Numbers v2.2.0

This is the changelog for Cldr v2.2.0 released on Febriuary 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

## Bug Fixes

* Fix generating an error tuple when the number system is a binary

* Fix `@doc` errors

## Enhancements

* Adds `Cldr.Number.Symbol.all_decimal_symbols/1` and `Cldr.Number.Symbol.all_grouping_symbols/1` that support parsing of numbers.  The symbols are returned as a list.

* Adds `Cldr.Number.Symbol.all_decimal_symbols_class/1` and `Cldr.Number.Symbol.all_grouping_symbols_class/1`. The symbols are returned as a `String.t` which can then be used to define a character class when building a regex.

## Cldr_Numbers v2.1.1

This is the changelog for Cldr v2.1.1 released on February 3rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

## Bug Fixes

* Formats `Decimal.new("-0")` the same as `Decimal.new("0")` which is to say without the sign.  Although the [Decimal standard](http://speleotrove.com/decimal/damisc.html#refcotot) upon which the [Decimal](https://github.com/ericmj/decimal) library is based allows for `-0`, formatting this as a string with the sign is not consistent with the output for integers and floats.  Consistency is, in this case, considered to be the correct approach.

* Fix documentation errors

## Cldr_Numbers v2.1.0

This is the changelog for Cldr v2.1.0 released on December 1st, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

## Enhancements

* Added `Cldr.Number.to_at_least_string/3`, `Cldr.Number.to_at_most_string/3`, `Cldr.Number.to_range_string/3` and `Cldr.Number.to_approx_string/3` to format numbers in way that conveys the relevant intent. These functions are also defined one each backend. For example, in the `"en"` locale:

```
iex> MyApp.Cldr.Number.to_at_least_string 1234
{:ok, "1,234+"}

iex> MyApp.Cldr.Number.to_at_most_string 1234
{:ok, "≤1,234"}

iex> MyApp.Cldr.Number.to_approx_string 1234
{:ok, "~1,234"}

iex> MyApp.Cldr.Number.to_range_string 1234..5678
{:ok, "1,234–5,678"}
```

* Refactored options for `Cldr.Numbers.to_string/3` and other functions that use the common number formatting options structure.  Options are now parsed and contained in a `Cldr.Number.Format.Options` struct. A user-visible benefit is that if passing a `Cldr.Number.Format.Options` struct to `Cldr.Number.to_string/3` then no further validation or normalization will be performed.  Therefore if you are formatting in a tight loop and using common options, saving the options in advance will yield some performance improvement.  A `Cldr.Number.Format.Options` struct can be returned by called `Cldr.Number.Format.Options.validate_options(backend, options)`.

## Cldr_Numbers v2.0.0

This is the changelog for Cldr v2.0.0 released on November 22nd, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/elixir-cldr/cldr_numbers/tags)

## Breaking Changes

* `ex_cldr_numbers` now depends upon [ex_cldr version 2.0](https://hex.pm/packages/ex_cldr/2.0.0).  As a result it is a requirement that at least one backend module be configured as described in the [ex_cldr readme](https://hexdocs.pm/ex_cldr/2.0.0/readme.html#configuration).

* The public API is now based upon functions defined on a backend module. Therefore calls to functions such as `Cldr.Number.to_string/2` should be replaced with calls to `MyApp.Cldr.Number.to_string/2` (assuming your configured backend module is called `MyApp.Cldr`).

### Enhancements

* Adds `Cldr.Number.validate_number_system/3` and `<backend>.Number.validate_number_system/2` that are now the canonical way to validate and return a number system from either a number system binary or atom, or from a number system name.

* `Cldr.Number.{Ordinal, Cardinal}.pluralize/3` now support ranges, not just numbers

* Currency spacing is now applied for currency formatting.  Depending on the locale, some text may be placed between the current symbol and the number.  This enhanced readability, it does not change the number formatting itself.  For example you can see below that for the locale "en", when the currency symbol is text, a non-breaking space is introduced between it and the number.

```
iex> MyApp.Cldr.Number.to_string 2345, currency: :USD, format: "¤#,##0.00"
{:ok, "$2,345.00"}

iex> MyApp.Cldr.Number.to_string 2345, currency: :USD, format: "¤¤#,##0.00"
{:ok, "USD 2,345.00"}
```