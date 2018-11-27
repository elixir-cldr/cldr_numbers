# Changelog for Cldr_Numbers v2.1.0

This is the changelog for Cldr v2.1.0 released on _______, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Enhancements

* Added `Cldr.Number.to_at_least/3`, `Cldr.Number.to_at_most/3`, `Cldr.Number.to_range/3` and `Cldr.Number.to_approximately/3` to format numbers in way that conveys the relevant intent. These functions are also defined one each backend. For example, in the `"en"` locale:

```
iex> TestBackend.Cldr.Number.to_at_least 1234
{:ok, "1,234+"}

iex> TestBackend.Cldr.Number.to_at_most 1234
{:ok, "≤1,234"}

iex> TestBackend.Cldr.Number.to_approximately 1234
{:ok, "~1,234"}

iex> TestBackend.Cldr.Number.to_range 1234..5678
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
iex> TestBackend.Cldr.Number.to_string 2345, currency: :USD, format: "¤#,##0.00"
{:ok, "$2,345.00"}

iex> TestBackend.Cldr.Number.to_string 2345, currency: :USD, format: "¤¤#,##0.00"
{:ok, "USD 2,345.00"}
```