defmodule Dash.MixProject do
  use Mix.Project

  def project do
    [
      app: :dash,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      preferred_cli_target: [run: :host, test: :host, "phx.server": :host],
      deps: deps(),
    ]
  end

  def aliases do
    [
      # test: "test --no-start",
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DashApplication, []},
      extra_applications: [:crypto],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Other deps
      {:mahaul, "~> 0.6"},
      {:zoneinfo, "~> 0.1.5"},
      {:machete, ">= 0.0.0", only: [:test]},
      {:efx, "~> 0.2.0"},
      # {:efx, path: "~/dev/forks/efx"},
      # {:machete, path: "~/dev/forks/machete", only: [:test]},
      {:quantum, "~> 3.0"},
      # A tiny bit weird to rely on this for hosts
      {:vintage_net, "~> 0.13.0"},
      # {:mahaul, path: "~/dev/forks/mahaul"},
      {:data_tracer, ">= 0.0.0"},
      {:contex, ">= 0.0.0"},
      {:dotenv_parser, "~> 2.0", only: :dev},
      {:ecto_sqlite3, "~> 0.7"},
      {:exsync, path: "~/dev/forks/exsync", override: true, only: :dev},
      # {:exsync, "~> 0.3", only: :dev},
      {:freedom_formatter, "~> 2.0"},
      {:mneme, ">= 0.0.0", only: :test},
      {:nimble_csv, "~> 1.2"},
      {:nimble_parsec, "~> 1.2"},
      {:phoenix_pubsub, "~> 2.1"},
      {:req, "~> 0.5"},
      {:scenic, "~> 0.11"},
      {:scenic_driver_local, "~> 0.11.0", only: :dev},
      {:scenic_live_reload, "~> 0.3.0", only: :dev},
      # {:scenic_widget_contrib, path: "~/dev/forks/scenic-widget-contrib"},
      {:scenic_widget_contrib, github: "axelson/scenic-widget-contrib", branch: "jax"},
      # {:scenic_widget_contrib, github: "axelson/scenic-widget-contrib", branch: "draw-utils"},
      {:typed_struct, "~> 0.3.0"},
    ]
  end
end
