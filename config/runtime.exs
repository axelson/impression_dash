import Config

if Config.config_env() == :dev do
  DotenvParser.load_file(".env")
end
