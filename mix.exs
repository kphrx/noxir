defmodule Noxir.MixProject do
  use Mix.Project

  @version "0.1.0"
  @scm_url "https://github.com/kphrx/noxir"

  def project do
    [
      app: :noxir,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      source_url: @scm_url,
      docs: docs(),
      name: "Noxir",
      description: "Nostr Relay in Elixir with Mnesia"
    ]
  end

  def cli do
    [
      preferred_envs: [credo: :test, dialyzer: :test, docs: :docs]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :memento],
      mod: {Noxir.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:memento, "~> 0.3"},
      {:websock_adapter, "~> 0.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :docs, runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mnesia],
      flags: [
        :error_handling,
        :underspecs,
        :unmatched_returns,
        # :overspecs,
        # :specdiffs,
        :extra_return,
        :missing_return
      ],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v" <> @version,
    ]
  end
end
