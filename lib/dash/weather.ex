defmodule Dash.Weather do
  # def request(%Dash.Location{latlon: _latlon}) do
  #   Process.sleep(500)

  #   %Dash.WeatherResult{
  #     temperature: 72.39,
  #     summary: "Windy",
  #     icon: "wind",
  #     humidity: 0.75,
  #     feel_like_temperature: 82.96
  #   }
  # end

  def request(%Dash.Location{latlon: latlon}) do
    api_key = Dash.Env.pirate_weather_api_key()
    res = Req.get!("https://api.pirateweather.net/forecast/#{api_key}/#{latlon}?exclude=alerts,minutely,hourly,daily")
    Dash.Weather.parse_result(res.body)
  end

  # https://github.com/jjasghar/pirateweather/blob/ccccc1b67345611bd14d6eeeb49cd9cdc953c3f5/docs/API.md
  def parse_result(result) do
    cur = result["currently"]

    %Dash.WeatherResult{
      feel_like_temperature: cur["apparentTemperature"],
      humidity: cur["humidity"],
      icon: cur["icon"],
      summary: cur["summary"],
      temperature: cur["temperature"]
    }
  end

  def weather_icon(dark_sky_icon) do
    # lightning.png
    case dark_sky_icon do
      "clear-day" -> "sun.png"
      "clear-night" -> "night.png"
      "rain" -> "rain.png"
      "snow" -> "snowflake.png"
      "sleet" -> "sleet.png"
      "wind" -> "wind.png"
      "fog" -> "mist.png"
      "cloudy" -> "cloud.png"
      "partly-cloudy-day" -> "partly_cloudy.png"
      "partly-cloudy-night" -> "partly_cloudy.png"
    end
  end
end
