# Changelog

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
