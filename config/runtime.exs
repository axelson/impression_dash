import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

config :dash,
  debug_logging: false,
  # gh_stats_base_url: "http://192.168.1.2:4004",
  gh_stats_base_url: "http://localhost:4000",
  # Use scale of 2 so I can actually read the display in host mode
  scale: 2,
  locations: [
    # %Dash.Location{
    #   name: "Iberian",
    #   location_name: "Spain",
    #   latlon: "0.433333,-3.7",
    #   tz: "Europe/Madrid",
    #   start_time: ~T[10:00:00],
    #   partial_finish_time: ~T[18:00:00],
    #   finish_time: ~T[23:00:00],
    #   gh_login: nil,
    # },
    # %Dash.Location{
    #   name: "New York",
    #   location_name: "New York, NY",
    #   latlon: "44.475833,-73.211944",
    #   tz: "America/New_York",
    #   start_time: ~T[10:00:00],
    #   partial_finish_time: ~T[18:00:00],
    #   finish_time: ~T[22:00:00],
    #   gh_login: nil,
    # },
    %Dash.Location{
      name: "Felt HQ",
      location_name: "Oakland, CA",
      latlon: "37.8075,-122.26749",
      tz: "America/Los_Angeles",
      start_time: ~T[08:00:00],
      partial_finish_time: ~T[18:00:00],
      finish_time: ~T[20:00:00],
      gh_login: nil,
    },
    %Dash.Location{
      name: "Home",
      location_name: "Honolulu, HI",
      latlon: "21.3069,-157.8583",
      tz: "Pacific/Honolulu",
      start_time: ~T[06:00:00],
      partial_finish_time: ~T[17:00:00],
      finish_time: ~T[20:00:00],
      gh_login: "axelson",
    },
  ]

config :dash, Dash.QuantumScheduler,
  jobs: [
    {"*/30 * * * *", fn -> Dash.Weather.Server.update_weather() end},
  ]

Code.require_file("/mnt/arch_linux/home/jason/dev/inky_impression_livebook/.target.secret.exs")
