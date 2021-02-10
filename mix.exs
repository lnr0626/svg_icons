defmodule SvgIcons.MixProject do
  use Mix.Project

  def project do
    [
      app: :svg_icons,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.5"},
      {:surface, "~> 0.2", only: [:test]}
    ]
  end
end
