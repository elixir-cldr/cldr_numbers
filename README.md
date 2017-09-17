# Number and Currency Localization and Formatting
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_numbers)
![Deps Status](https://beta.hexfaktor.org/badge/all/github/kipcole9/cldr_numbers.svg)
[![Hex pm](http://img.shields.io/hexpm/v/ex_cldr_numbers.svg?style=flat)](https://hex.pm/packages/ex_cldr_numbers)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/kipcole9/cldr_numbers/blob/master/LICENSE)

## Introduction and Getting Started

`ex_cldr_numbers` is an addon library application for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localisation and formatting for numbers and currencies.

The primary api is `Cldr.Number.to_string/2`.  The following examples demonstrate:

```elixir
iex> Cldr.Number.to_string 12345
{:ok, "12,345"}

iex> Cldr.Number.to_string 12345, locale: "fr"
{:ok, "12 345"}

iex> Cldr.Number.to_string 12345, locale: "fr", currency: "USD"
{:ok, "12 345,00 $US"}

iex> Cldr.Number.to_string 12345, format: "#E0"
{:ok, "1.2345E4"}
```

For help in `iex`:

```elixir
iex> h Cldr.Date.to_string
iex> h Cldr.Time.to_string
iex> h Cldr.DateTime.to_string
iex> h Cldr.DateTime.Relative.to_string
```
## Documentation

Primary documentation is available on [as part of the ex_cldr documentation on hex](https://hexdocs.pm/ex_cldr/3_number_formats.html)

## Known restrictions and limitations

## Installation

Note that `:ex_numbers` requires Elixir 1.5 or later.

Add `ex_cldr_numbers` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_numbers, "~> 0.1.0"}
      ]
    end

then retrieve `ex_cldr_numbers` from [hex](https://hex.pm/packages/ex_numbers):

    mix deps.get
    mix deps.compile
