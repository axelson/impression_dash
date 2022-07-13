import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end

config :dash, :trello_api_key, System.get_env("TRELLO_API_KEY")
config :dash, :trello_api_token, System.get_env("TRELLO_API_TOKEN")
