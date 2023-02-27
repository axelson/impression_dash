defmodule Dash.Env do
  use Mahaul,
    TRELLO_API_KEY: [type: :str],
    TRELLO_API_TOKEN: [type: :str],
    PIRATE_WEATHER_API_KEY: [type: :str],
    MY_KEY: [type: :afesofesf],
    PORT: [type: :port, default_dev: "4000"],
    DEPLOYMENT_ENV: [type: :enum, choices: [:dev, :staging, :live], default_dev: "dev"],
    DATABASE_URL: [type: :uri, default_dev: "postgresql://user:pass@localhost:5432/app_dev"],
    ANOTHER_ENV: [type: :host, default: "//localhost"]
end
