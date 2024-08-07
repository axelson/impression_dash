import Config

# It's a little weird to set mix_env like this
config :mahaul, mix_env: Mix.env()

config :elixir, time_zone_database: Zoneinfo.TimeZoneDatabase

config :vintage_net,
  resolvconf: "/dev/null",
  persistence: VintageNet.Persistence.Null

config :dash, wait_for_network: false

config :dash, Dash.Repo,
  database: "priv/dash_database.db",
  migration_primary_key: [type: :binary_id],
  journal_mode: :wal,
  cache_size: -64_000,
  temp_store: :memory,
  pool_size: 1

config :dash, ecto_repos: [Dash.Repo]
config :dash, :timezone, "Pacific/Honolulu"

# connect the app's asset module to Scenic
config :scenic, :assets, module: Dash.Assets

case Mix.env() do
  :dev ->
    config :dash, :viewport,
      name: :main_viewport,
      # Make the ssize match the impression's resolution
      # 5.7"
      # size: {600, 448},
      # 7.3"
      # size: {800, 480},
      # local dev
      size: {800 * 1, 480 * 1},
      theme: :dark,
      default_scene: Dash.Scene.Home,
      # default_scene: Dash.Scene.HomeOld,
      # default_scene: Dash.Scene.HomeScaled,
      drivers: [
        [
          module: Scenic.Driver.Local,
          name: :local,
          window: [resizeable: false, title: "dash"],
          on_close: :stop_system,
        ],
      ]

    config :exsync,
      reload_timeout: 150,
      reload_callback: {ScenicLiveReload, :reload_current_scenes, []}

  :test ->
    config :dash, start_weather_server: false

    config :logger,
      level: :info

  _ ->
    nil
end

config :logger, :console,
  metadata: [:mfa, :line],
  format: "$time $metadata[$level]:\n$message\n\n"

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "prod.exs"
