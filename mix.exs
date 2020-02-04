defmodule Auth0Jwks.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth0_jwks,
      version: "0.1.0",
      elixir: "~> 1.10",
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
      {:joken, "~> 2.0"},
      {:joken_jwks, "~> 1.1.0"},
      {:plug_cowboy, "~> 2.0"},
    ]
  end
end
