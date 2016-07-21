defmodule Whatwasit.Mixfile do
  use Mix.Project

  def project do
    [app: :whatwasit,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: applications(Mix.env)]
  end

  defp applications(:test), do: [:logger, :ecto, :postgrex]
  defp applications(_), do: [:logger, :ecto]

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:phoenix, "~> 1.1"},
      {:postgrex, ">= 0.0.0", only: :test},
    ]
  end
end
