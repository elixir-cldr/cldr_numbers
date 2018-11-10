# Changelog for Cldr_Numbers v2.0.0-rc.0

This is the changelog for Cldr v2.0.0-rc.0 released on October 18th, 2018.  For older changelogs please consult the release tag on [GitHub](https://github.com/kipcole9/cldr_numbers/tags)

## Breaking Changes

* `ex_cldr_numbers` now depends upon [ex_cldr version 2.0](https://hex.pm/packages/ex_cldr/2.0.0-rc.0).  As a result it is a requirement that at least one backend module be configured as described in the [ex_cldr readme](https://hexdocs.pm/ex_cldr/2.0.0-rc.0/readme.html#configuration).

* The public API is now based upon functions defined on a backend module. Therefore calls to functions such as `Cldr.Number.to_string/2` should be replaced with calls to `MyApp.Cldr.Number.to_string/2` (assuming your configured backend module is called `MyApp.Cldr`).
