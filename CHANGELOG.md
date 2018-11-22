# Changelog for Cldr_Numbers v2.0.0

This is the changelog for Cldr v2.0.0 released on November 22nd, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Breaking Changes

* `ex_cldr_numbers` now depends upon [ex_cldr version 2.0](https://hex.pm/packages/ex_cldr/2.0.0).  As a result it is a requirement that at least one backend module be configured as described in the [ex_cldr readme](https://hexdocs.pm/ex_cldr/2.0.0/readme.html#configuration).

* The public API is now based upon functions defined on a backend module. Therefore calls to functions such as `Cldr.Number.to_string/2` should be replaced with calls to `MyApp.Cldr.Number.to_string/2` (assuming your configured backend module is called `MyApp.Cldr`).

### To do before final release

* [ ] Revisit Cldr.Number.validate_number_system (the contract needs clarification but should follow the Cldr.validate_locale principles) This is an update to the base `ex_cldr` package, not numbers.
* [ ] Add Cldr.Number.Format.Options struct to hold the options structure for `to_string/2`
* [ ] When `to_string/2` is passed options that are the struct, don't do any further validation.  The validation process is quite expensive and therefore by creating a validated options struct that can be reused we can optimize performance (benchmark this too)