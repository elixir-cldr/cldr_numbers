# Changelog for Cldr_Numbers v1.5.1

This is the changelog for Cldr v1.5.1 released on July 20th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Bug Fixes

* Removes generated *.erl files from the package definition.  This ensures that the correct version of erlang `parse_tools` is used when generating code from `leex` and `yecc`

# Changelog for Cldr_Numbers v1.5.0

This is the changelog for Cldr Numbers v1.5.0 released on July 8th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Enhancements

* Add the optional argument `:minimum_grouping_digits` to `Number.to_string/2`.  For an understanding of the meaning of minimum grouping digits, consult this [section](https://unicode.org/reports/tr35/tr35-numbers.html#Examples_of_minimumGroupingDigits) of [TR35](https://unicode.org/reports/tr35/tr35-numbers.html).  The use of this option should be considered exceptional - its use is to override the minimum grouping digits defined for a locale.

# Changelog for Cldr_Numbers v1.4.4

This is the changelog for Cldr Numbers v1.4.2 released on May 30th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Enhancements

* Relaxes the requirement for [ex_cldr](https://hex.pm/packages/ex_cldr)

# Changelog for Cldr_Numbers v1.4.3

This is the changelog for Cldr Numbers v1.4.2 released on May 28th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Enhancements

* Extracts the data encapsultion for currencies to its own package [ex_cldr_currencies](https://hex.pm/packages/ex_cldr_currencies).  This package is a dependency here and optionally for the package [ex_cldr_html](https://hex.pm/packages/ex_cldr_html)

# Changelog for Cldr_Numbers v1.4.2

This is the changelog for Cldr Numbers v1.4.2 released on April 9th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Enhancements

* Supports formatting valid but unknown currency codes.  These codes are defined by ISO4217 to begin with "X" and have two following alphabetic characters.  Since these currency codes are valid but unknown to `Cldr`, the formatted output is based upon incomplete information.

# Changelog for Cldr_Numbers v1.4.1

### Enhancements

* Update ex_cldr dependency to version 1.5.1 so we can use `Cldr.Config.app_name/0` instead of hard-coding the app name `:ex_cldr`

# Changelog for Cldr_Numbers v1.4.0

This is the changelog for Cldr v1.4.0 released on March 29th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Enhancements

* Update ex_cldr dependency to version 1.5.0 which uses CLDR data version 33.

# Changelog for Cldr_Numbers v1.3.1

This is the changelog for Cldr v1.3.1 released on February 19th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Enhancements

* Performance improvement for zero padding numbers during formatting

# Changelog for Cldr_Numbers v1.3.0

### Enhancements

* In certain cases the ISO definition of a currencies decimal digits (subunit) differs from CLDR. One such example is the Colombian Peso where Cldr has the number of digits as 0 whereas ISO4217 has the number of digits as 2.  Cldr 1.4 adds a field `:iso_digits` to the `Cldr.Currency` struct to allow the selection of the ISO definition as an option.

* As a result the `Cldr.Number.to_string/2` option `cash: <boolean>` is deprecated and a new option `:currency_digits` is introduced.  The valid options for `:currency_digits` are `:accounting` (the default), `:cash` and `:iso`.

* Requires `ex_cldr` version 1.4 or later

### Deprecations

* The option `cash: <boolean>` for `Cldr.Number.to_string/2` is deprecated and will be removed in `cldr_numbers` version 2.0.

# Changelog for Cldr_Numbers v1.2.0

This is the changelog for Cldr v1.2.0 released on January 14th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Enhancements

* Add `Cldr.Number.precision/1` tor return the number of digits in a float, integer or Decimal.  This function delegates to `Cldr.Digits.number_of_digits/1`

* `Cldr.Number.String.chunk_string/3` is now Elixir version dependent since in Elixir version 1.7 `String.chunk/4` is deprecated in favour of `String.chunk_every/4`

# Changelog for Cldr_Numbers v1.1.1

## Enhancements

* Format the code with the Elixir 1.6 code formatter

# Changelog for Cldr_Numbers v1.1

This is the changelog for Cldr v1.1.0 released on December 22nd, 2017.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Bug fixes

* Fixes a bug whereby an exception would be raised if a number format was specified as a `:spellout` or `:ordinal` but the locale doesn't support them

## Enhancements

* Support RBNF formats for `Decimal` numbers that are integers (ie where the exponent is zero) since these are equivalent to their integer counterparts.  `Decimals` where the `exp` is not zero remain unsupported since the underlying rules engine only knows how to work on `numbers` (integer or float) and it would not be appropriate to convert to a float due to the loss of precision and the fact that the numbers would not round trip.

* Changed the exception name `Cldr.NoRbnf` to a more meaningful `Cldr.Rbnf.NoRule`
