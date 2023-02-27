defmodule Dash.Location do
  use TypedStruct

  typedstruct do
    field :name, String.t(), enforce: true
    field :latlon, String.t(), enforce: true
  end
end

defmodule Dash.Locations do
  def all do
    [
      %Dash.Location{
        name: "Honolulu",
        latlon: "21.3069,-157.8583"
      },
      %Dash.Location{
        name: "Oakland",
        latlon: "37.8075,-122.26749"
      }
    ]
  end
end
