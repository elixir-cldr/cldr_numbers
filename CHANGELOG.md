# Changelog

## Cldr_Numbers v0.3.3 November 12th, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.13.0

## Cldr_Numbers v0.3.2 November 8th, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.12.0

## Cldr_Numbers v0.3.1 November 3rd, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.11.0 in which the term `territory` is preferred over `region`

## Cldr_Numbers v0.3.0 November 2nd, 2017

### Enhancements

* Update to [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.10.0 which incorporates CLDR data version 32 released on November 1st, 2017.  For further information on the changes in CLDR 32 release consult the [release notes](http://cldr.unicode.org/index/downloads/cldr-32).

## Cldr_Numbers v0.2.3 November 1st, 2017

### Enhancements

* Move to `ex_cldr` 0.9.0

## Cldr_Numbers v0.2.2 October 30th, 2017

### Enhancements

* Move to `ex_cldr` 0.8.2 which changes Cldr.Number.PluralRule.plural_rule/3 implementation for Float so that it no longer casts to a Decimal nor delegates to the Decimal path".  This will have a small positive impact on performance

## Cldr_Numbers v0.2.1 October 30th, 2017

### Bug Fixes

* Ensures currency structs are built at compile (thanks to @danschultzer)

## Cldr_Numbers v0.2.0 October 25th, 2017

### Breaking changes

* As of [ex_cldr](https://hex.pm/packages/ex_cldr) version 0.8.0 the locale is now managed as a struct.  This should not affect most applications but since it does change some function calls the minor version is bumped.

## Cldr_Numbers v0.1.0 September 18th, 2017

* Initial release
