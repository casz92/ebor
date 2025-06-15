defmodule Ebor.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :ebor,
      version: @version,
      elixir: "~> 1.14",
      description: "A custom CBOR library with tuples support",
      package: package(),
      start_permanent: Mix.env() == :prod,
      docs: [main: "readme", extras: ["README.md"]],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, "~> 0.31", only: :dev, runtime: false}]
  end

  def package do
    [
      name: "ebor",
      maintainers: ["Carlos Suarez"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/casz92/ebor"}
    ]
  end
end
