## Changelog for Cldr_Numbers v1.2

This is the changelog for Cldr v1.2.0 released on December 31st, 2017.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Enhancements

* Format the code with the Elixir 1.6 code formatter

## Changelog for Cldr_Numbers v1.1

This is the changelog for Cldr v1.1.0 released on December 22nd, 2017.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Bug fixes

* Fixes a bug whereby an exception would be raised if a number format was specified as a `:spellout` or `:ordinal` but the locale doesn't support them

## Enhancements

* Support RBNF formats for `Decimal` numbers that are integers (ie where the exponent is zero) since these are equivalent to their integer counterparts.  `Decimals` where the `exp` is not zero remain unsupported since the underlying rules engine only knows how to work on `numbers` (integer or float) and it would not be appropriate to convert to a float due to the loss of precision and the fact that the numbers would not round trip.

* Changed the exception name `Cldr.NoRbnf` to a more meaningful `Cldr.Rbnf.NoRule`

