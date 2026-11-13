# TODO

Known defects and parked work in `ex_cldr_numbers`. The library is in maintenance mode (see `STATUS.md`): defects users report are fixed and released, while defects found in review are recorded here and deferred, because development time goes to Localize. An item is revived when someone reports it.

## Open

* [ ] **Format with a quoted literal hangs** — `Cldr.Number.to_string(-2, MyApp.Cldr, format: "'abc' 0.0 'def'")` never returns, and neither does `Cldr.Number.Format.Compiler.format_to_metadata/1` on the same pattern, so a caller-supplied format can tie up a process. To be fixed before the next release. Found 2026-11-14 while scoping #68, not reported.

* [ ] **Scientific format of a Decimal raises** — `Cldr.Number.to_string(Decimal.new("-70000"), MyApp.Cldr, format: :scientific)` raises `FunctionClauseError` in every locale sampled, where an integer or float formats; zero raises in formats such as `0.###E0`, as a float too. Both come from `Cldr.Math.round_significant/2` in `cldr_utils`. Found 2026-11-14 while scoping #68, not reported.

## Deferred

* [ ] **Parse currency amounts formatted with currency separators** — since v2.38.4 `fr-CH` and `de-AT` format currency amounts with CLDR's currency separators, but `Cldr.Number.Parser.parse/2` and `scan/2` read only the plain-number ones: `parse/2` fails on `de-AT` "1.234,56" and `scan/2` splits both locales' amounts. ex_money 5.24's `Money.parse` fails on `de-AT` for the same reason. Localize's parser takes a `:currency` option for this. Found 2026-11-08 with PR #66, not reported.

* [ ] **ECMA-402 number options for MF2** — separate minimum and maximum fraction digits (not only `:fractional_digits`), significant digits, compact notation, `signDisplay` and `notation`, so MF2 number functions map onto the formatter. Functional work, parked by maintenance mode; Localize carries it.
