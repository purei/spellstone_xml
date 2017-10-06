defmodule SpellstoneXML.Mixfile do
  use Mix.Project

  def project do
    [
      app: :spellstone_xml,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {SpellstoneXML.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:map_diff, "~> 1.0"}
      {:sweet_xml, "~> 0.6"}, # XML parser
      {:poison, "~> 3.1"}, # JSON parser
      {:httpoison, "~> 0.10"}, # Http communicator
      {:deep_merge, "~> 0.1.0"} # Map merging across xml data
    ]
  end
end
