
# Changelog for Cldr_Numbers v2.4.3

This is the changelog for Cldr v2.4.2 released on March 20th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

### Bug Fixes

* Fix dialyzer warnings

# Changelog for Cldr_Numbers v2.4.2

This is the changelog for Cldr v2.4.2 released on March 15th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

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
# Changelog for Cldr_Numbers v2.4.1

This is the changelog for Cldr v2.4.1 released on March 7th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Bug Fixes

* Fix fractional grouping. Previously when there was no grouping, the group size was being set to the number of fractional digits.

* Fix scientific precision. Previously the mantissa was not being rounded because the prioritisation of significant digits over exponent digits was not being correctly reconciled.

* Fix formatting precision of an exponent. A format of `0E00` will now format the exponent with two digits.

* Fix o silence dialyzer warnings

# Changelog for Cldr_Numbers v2.4.0

This is the changelog for Cldr v2.4.0 released on March 4th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Enhancements

* Adds `Cldr.Number.Format.default_grouping_for/2` to return the default grouping of digits for a locale. This is useful for external number formats like [ex_cldr_print](https://github.com/kipcole9/cldr_print).

# Changelog for Cldr_Numbers v2.3.0

This is the changelog for Cldr v2.3.0 released on March 1st, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Enhancements

* Opens up the formatting pipeline for use by other formatting systems like `printf`. This is implemented by the introduction of `Cldr.Number.Format.Meta` to create the abstract metadata struct.  This struct is used for `Cldr.Number.to_string/3` and is now available for use by other libraries. The function `Cldr.Number.Formatter.Decimal.to_string/3` is the primary function that should be used by other libraries.

# Changelog for Cldr_Numbers v2.2.0

This is the changelog for Cldr v2.2.0 released on Febriuary 24th, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Bug Fixes

* Fix generating an error tuple when the number system is a binary

* Fix `@doc` errors

## Enhancements

* Adds `Cldr.Number.Symbol.all_decimal_symbols/1` and `Cldr.Number.Symbol.all_grouping_symbols/1` that support parsing of numbers.  The symbols are returned as a list.

* Adds `Cldr.Number.Symbol.all_decimal_symbols_class/1` and `Cldr.Number.Symbol.all_grouping_symbols_class/1`. The symbols are returned as a `String.t` which can then be used to define a character class when building a regex.

# Changelog for Cldr_Numbers v2.1.1

This is the changelog for Cldr v2.1.1 released on February 3rd, 2019.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Bug Fixes

* Formats `Decimal.new("-0")` the same as `Decimal.new("0")` which is to say without the sign.  Although the [Decimal standard](http://speleotrove.com/decimal/damisc.html#refcotot) upon which the [Decimal](https://github.com/ericmj/decimal) library is based allows for `-0`, formatting this as a string with the sign is not consistent with the output for integers and floats.  Consistency is, in this case, considered to be the correct approach.

* Fix documentation errors

# Changelog for Cldr_Numbers v2.1.0

This is the changelog for Cldr v2.1.0 released on December 1st, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

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

# Changelog for Cldr_Numbers v2.0.0

This is the changelog for Cldr v2.0.0 released on November 22nd, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Breaking Changes

* `ex_cldr_numbers` now depends upon [ex_cldr version 2.0](https://hex.pm/packages/ex_cldr/2.0.0).  As a result it is a requirement that at least one backend module be configured as described in the [ex_cldr readme](https://hexdocs.pm/ex_cldr/2.0.0/readme.html#configuration).

* The public API is now based upon functions defined on a backend module. Therefore calls to functions such as `Cldr.Number.to_string/2` should be replaced with calls to `MyApp.Cldr.Number.to_string/2` (assuming your configured backend module is called `MyApp.Cldr`).

### Enhancements

* Adds `Cldr.Number.validate_number_system/3` and `<backend>.Number.validate_number_system/2` that are now the canonical way to validate and return a number system from either a number system binary or atom, or from a number system name.

* `Cldr.Number.{Ordinal, Cardinal}.pluralize/3` now support ranges, not just numbers

* Currency spacing is now applied for currency formatting.  Depending on the locale, some text may be placed between the current symbol and the number.  This enhanced readibility, it does not change the number formatting itself.  For example you can see below that for the locale "en", when the currency symbol is text, a non-breaking space is introduced between it and the number.

```
iex> MyApp.Cldr.Number.to_string 2345, currency: :USD, format: "¤#,##0.00"
{:ok, "$2,345.00"}

iex> MyApp.Cldr.Number.to_string 2345, currency: :USD, format: "¤¤#,##0.00"
{:ok, "USD 2,345.00"}
```