defmodule Dash.Env do
  use Mahaul,
    TRELLO_API_KEY: [type: :str],
    TRELLO_API_TOKEN: [type: :str],
    PIRATE_WEATHER_API_KEY: [type: :str]
end
