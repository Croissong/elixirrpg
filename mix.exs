defmodule Elixirpg.Mixfile do
  use Mix.Project

  def project do
    [app: :expg,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cowboy, :plug, :porcelain, :timex, :logger , :maptu, :httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:rethinkdb, "~> 0.3.2"}, {:cowboy, "~> 1.0.0"}, {:plug, "~> 1.0"}, {:porcelain, "~> 2.0.1"},
     {:poison, "~> 2.0"}, {:timex, "~> 2.1.4"}, {:credo, "~> 0.3.10", only: [:dev, :test]},
     {:dialyxir, "~> 0.3.3", only: [:dev, :test]}, {:maptu, ">= 0.0.0"}, {:httpoison, "~> 0.8.0"}]
  end
end
