defmodule Cldr.Numbers.Mixfile do
  @moduledoc false

  use Mix.Project

  @version "2.28.0"

  def project do
    [
      app: :ex_cldr_numbers,
      version: @version,
      elixir: "~> 1.10",
      name: "Cldr Numbers",
      description: description(),
      source_url: "https://github.com/elixir-cldr/cldr_numbers",
      docs: docs(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore_warnings",
        plt_add_apps: ~w(inets jason mix)a
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Number and currency localization and formatting functions for the Common Locale Data
    Repository (CLDR).
    """
  end

  defp deps do
    [
      {:ex_cldr, "~> 2.34"},
      {:ex_cldr_currencies, ">= 2.14.2"},
      {:digital_token, "~> 0.3 or ~> 1.0"},

      {:decimal, "~> 1.6 or ~> 2.0"},
      {:jason, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.18", only: [:dev, :release], optional: true, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:exprof, "~> 0.2", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Kip Cole"],
      licenses: ["Apache-2.0"],
      links: links(),
      files: [
        "lib",
        "src/decimal_formats_lexer.xrl",
        "src/decimal_formats_parser.yrl",
        "src/rbnf_lexer.xrl",
        "src/rbnf_parser.yrl",
        "config",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"],
      logo: "logo.png",
      formatters: ["html"],
      skip_undefined_reference_warnings_on: ["changelog", "CHANGELOG.md"]
    ]
  end

  def links do
    %{
      "GitHub" => "https://github.com/elixir-cldr/cldr_numbers",
      "Readme" => "https://github.com/elixir-cldr/cldr_numbers/blob/v#{@version}/README.md",
      "Changelog" => "https://github.com/elixir-cldr/cldr_numbers/blob/v#{@version}/CHANGELOG.md"
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test", "mix"]
  defp elixirc_paths(:dev), do: ["lib", "mix"]
  defp elixirc_paths(_), do: ["lib"]
end
