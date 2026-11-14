# TODO

Known defects and parked work in `ex_cldr_numbers`. The library is in maintenance mode (see `STATUS.md`): defects users report are fixed and released, while defects found in review are recorded here and deferred, because development time goes to Localize. An item is revived when someone reports it.

## Deferred

* [ ] **Parse currency amounts formatted with currency separators** — since v2.38.4 `fr-CH` and `de-AT` format currency amounts with CLDR's currency separators, but `Cldr.Number.Parser.parse/2` and `scan/2` read only the plain-number ones: `parse/2` fails on `de-AT` "1.234,56" and `scan/2` splits both locales' amounts. ex_money 5.24's `Money.parse` fails on `de-AT` for the same reason. Localize's parser takes a `:currency` option for this. Found 2026-11-08 with PR #66, not reported.

* [ ] **ECMA-402 number options for MF2** — separate minimum and maximum fraction digits (not only `:fractional_digits`), significant digits, compact notation, `signDisplay` and `notation`, so MF2 number functions map onto the formatter. Functional work, parked by maintenance mode; Localize carries it.

## Done

* [x] **Scientific format of a Decimal raises** — fixed in `cldr_utils` 2.29.8, which is now required; zero in a scientific format no longer raises either. 2026-11-14, v2.38.5.

* [x] **Format with a quoted literal hangs** — the lexer no longer loops on a quoted literal or an unterminated quote, and quoted strings are literals. 2026-11-14, v2.38.5.
