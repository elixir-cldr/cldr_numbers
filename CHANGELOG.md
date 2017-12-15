# Changelog for Cldr_Numbers v1.0.2

This is the changelog for Cldr v1.0.2 released on _______.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Bug fixes

* Fixes a bug whereby an exception would be raised if a number format was specified as a `:spellout` or `:ordinal` but the locale doesn't support them

## Enhancements

* Changed the exception name `Cldr.NoRbnf` to  a more meaninful `Cldr.Rbnf.NoRule`

