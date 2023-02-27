defmodule Dash.WeatherResult do
  use TypedStruct

  typedstruct do
    field :feel_like_temperature, float(), enforce: true
    field :humidity, float(), enforce: true
    field :icon, String.t(), enforce: true
    field :summary, String.t(), enforce: true
    field :temperature, float(), enforce: true
  end
end
