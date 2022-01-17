defmodule SqlConv.MixProject do
  use Mix.Project

  def project do
    [
      app: :sql_conv,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def escript do
    [main_module: SqlConv]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      # mod: {SqlConv.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:nimble_csv, "~> 0.7.0"},
      {:cli_spinners, "~> 0.1.0"},
      {:sizeable, "~> 1.0"},
      {:poolboy, "~> 1.5.1"}
    ]
  end
end
