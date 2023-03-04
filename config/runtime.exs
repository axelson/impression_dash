import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

config :dash,
  locations: [
    %Dash.Location{
      name: "Vermont",
      location_name: "Burlington, Vermont",
      latlon: "44.475833,-73.211944",
    },
    %Dash.Location{
      name: "Home",
      location_name: "Honolulu, HI",
      latlon: "21.3069,-157.8583",
    },
    %Dash.Location{
      name: "Felt HQ",
      location_name: "Oakland, CA",
      latlon: "37.8075,-122.26749",
    },
  ]
