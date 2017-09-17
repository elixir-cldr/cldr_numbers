defmodule CldrNumbers.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cldr_numbers,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_cldr, path: "../cldr"},
      {:poison, "~> 2.1 or ~> 3.0"},
      {:decimal, "~> 1.4"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "mix", "test"]
  defp elixirc_paths(:dev),  do: ["lib", "mix"]
  defp elixirc_paths(_),     do: ["lib"]
end
