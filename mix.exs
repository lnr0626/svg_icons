defmodule SvgIcons.MixProject do
  use Mix.Project

  @version "0.2.1"

  def project do
    [
      app: :svg_icons,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: """
      A library for rendering inline svgs with Phoenix, Phoenix LiveView, and Surface.
      """,
      source_url: "https://github.com/lnr0626/svg_icons.git",
      package: package()
    ]
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/lnr0626/svg_icons"}
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
      {:jason, "~> 1.0"},
      {:surface, "~> 0.4", only: [:test]},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
