# Number and Currency Localization and Formatting
![Build Status](http://sweatbox.noexpectations.com.au:8080/buildStatus/icon?job=cldr_numbers)
![Deps Status](https://beta.hexfaktor.org/badge/all/github/kipcole9/cldr_numbers.svg)
[![Hex pm](http://img.shields.io/hexpm/v/ex_cldr_numbers.svg?style=flat)](https://hex.pm/packages/ex_cldr_numbers)
[![License](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://github.com/kipcole9/cldr_numbers/blob/master/LICENSE)

## Introduction and Getting Started

[ex_cldr_numbers](https://hex.pm/packages/ex_cldr_numbers) is an addon library application for [ex_cldr](https://hex.pm/packages/ex_cldr) that provides localization and formatting for numbers and currencies.

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
iex> h Cldr.Number.to_string
```
## Documentation

Primary documentation is available [as part of the ex_cldr documentation on hex](https://hexdocs.pm/ex_cldr/3_number_formats.html)

## Known restrictions and limitations

TR35 states that for scientific formats (i.e. mantissa and exponent):

> The maximum number of integer digits, if present, specifies the exponent grouping. The most common use of this is to generate engineering notation, in which the exponent is a multiple of three, for example, "##0.###E0". The number 12345 is formatted using "##0.####E0" as "12.345E3".

`ex_cldr_numbers` does not currently support such functionality.

## Installation

Note that [ex_cldr_numbers](https://hex.pm/packages/ex_cldr_numbers) requires Elixir 1.5 or later.

Add `ex_cldr_numbers` as a dependency to your `mix` project:

    defp deps do
      [
        {:ex_cldr_numbers, "~> 0.3.1"}
      ]
    end

then retrieve `ex_cldr_numbers` from [hex](https://hex.pm/packages/ex_cldr_numbers):

    mix deps.get
    mix deps.compile
