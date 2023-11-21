defmodule Noxir.MixProject do
  use Mix.Project

  def project do
    [
      app: :noxir,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  def cli do
    [
      preferred_envs: [credo: :test, dialyzer: :test]
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
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
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
end
