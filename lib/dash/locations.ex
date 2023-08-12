defmodule Dash.Location do
  use TypedStruct

  typedstruct do
    field :name, String.t(), enforce: true
    field :location_name, String.t(), enforce: true
    field :latlon, String.t(), enforce: true
    field :tz, String.t()
    field :start_time, Time.t()
    field :partial_finish_time, Time.t()
    field :finish_time, Time.t()
    field :gh_login, String.t()
  end
end

defmodule Dash.Locations do
  def all do
    Application.fetch_env!(:dash, :locations)
  end
end
