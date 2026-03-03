defmodule AppleAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :apple_auth,
      description:
        "Apple Sign in with Apple (SIWA) token validation and authorization code exchange",
      version: "0.1.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: aliases()
    ]
  end

  def cli do
    [preferred_envs: [test: :test]]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AppleAuth.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:jose, "~> 1.11"},
      {:joken, "~> 2.6"},
      {:plug, "~> 1.15"},
      {:mox, "~> 1.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/dvcrn/apple_auth"}
    ]
  end

  defp aliases do
    [
      lint: ["credo --strict", "dialyzer"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
