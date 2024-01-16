defmodule Noxir.MixProject do
  use Mix.Project

  @version "0.1.0"
  @scm_url "https://github.com/kphrx/noxir"

  def project do
    [
      app: :noxir,
      version: version(),
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

  defp is_not_found_git do
    "git"
    |> System.find_executable()
    |> is_nil()
  end

  defp git_tag do
    if is_not_found_git() do
      nil
    else
      case System.cmd("git", ["-P", "tag", "--points-at", "HEAD"], stderr_to_stdout: true) do
        {tag, 0} -> String.trim(tag)
        _ -> nil
      end
    end
  end

  defp git_short_hash do
    if is_not_found_git() do
      nil
    else
      case System.cmd("git", ["rev-parse", "--short", "HEAD"], stderr_to_stdout: true) do
        {hash, 0} -> String.trim(hash)
        _ -> nil
      end
    end
  end

  defp prerelease do
    "NOXIR_PRERELEASE"
    |> System.get_env("dev")
    |> String.trim()
    |> then(fn
      "dev" ->
        case git_tag() do
          "v" <> @version <> "-" <> tag_prerelease -> tag_prerelease
          "v" <> @version <> _ -> ""
          _ -> "dev"
        end

      v ->
        v
    end)
  end

  defp vcs_ref do
    "NOXIR_VCS_REF"
    |> System.get_env("")
    |> String.trim()
    |> then(fn
      "" ->
        case git_short_hash() do
          git_ref when is_binary(git_ref) -> git_ref
          nil -> nil
        end

      v ->
        v
    end)
  end

  defp version do
    with "dev" <- prerelease(),
         vcs_ref <- vcs_ref(),
         false <- is_nil(vcs_ref) do
      @version <> "-dev" <> "+" <> vcs_ref
    else
      true -> @version <> "-dev"
      "" -> @version
      v -> @version <> "-" <> v
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:cors_plug, "~> 3.0"},
      {:jason, "~> 1.4"},
      {:memento, "~> 0.3"},
      {:websock_adapter, "~> 0.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:erlex, github: "bradhanks/erlex", only: [:dev, :test], runtime: false, override: true},
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
      source_ref: source_ref()
    ]
  end

  defp source_ref do
    case version() do
      @version <> "-dev" <> _ -> "master"
      semver -> "v" <> semver
    end
  end
end
