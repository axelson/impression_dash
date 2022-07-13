defmodule Dash.MixProject do
  use Mix.Project

  def project do
    [
      app: :dash,
      version: "0.1.0",
      elixir: "~> 1.7",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {DashApplication, []},
      extra_applications: [:crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scenic_widget_contrib, path: "~/dev/forks/scenic-widget-contrib"},
      {:phoenix_pubsub, "~> 2.1"},
      {:scenic_live_reload, github: "axelson/scenic_live_reload", branch: "wip-v0.11", only: :dev},
      {:scenic, "~> 0.11.0-beta.0"},
      {:scenic_driver_local, "~> 0.11.0-beta.0", targets: :host}
    ]
  end
end
