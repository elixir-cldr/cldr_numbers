Primarily to integrate better with MF2

* Support the Intl.Number options (see their docs)
* Support separate minimum_fractional_digits and maximum_fractional_digits, not just fractional_digits
* Investigate significant digits
* Investigate compact format
* Investigate signDisplay, notation

* Fix The type needs to be :Cardinal / :Ordinal (capitalized). for the function Cldr.Number.PluralRule.plural_type(123, type: Ordinal)  :few
* Fix the doctests for the function, the formatting is wrong (not indented enough)
