defmodule Dash.Components.WorkStatusComponent do
  use Scenic.Component, has_children: false
  import Scenic.Primitives
  alias Scenic.Graph

  @type work_status() :: :yes | :partial | :no

  @impl Scenic.Component
  def validate(params) do
    if [:start_time, :partial_finish_time, :finish_time, :tz] -- Map.keys(params) == [] do
      {:ok, params}
    else
      {:error, "Missing keys! Received #{Map.keys(params)}"}
    end
  end

  @impl Scenic.Scene
  def init(scene, params, _opts) do
    start_time = params[:start_time]
    partial_finish_time = params[:partial_finish_time]
    finish_time = params[:finish_time]
    tz = params[:tz]

    now = DateTime.now!(tz)
    date = DateTime.to_date(now)
    start = DateTime.new!(date, start_time, tz)
    partial = DateTime.new!(date, partial_finish_time, tz)
    finish = DateTime.new!(date, finish_time, tz)

    fill =
      case working(now, start, partial, finish) do
        :no -> :red
        :yes -> :green
        :partial -> :yellow
      end

    graph =
      Graph.build()
      |> circle(6, fill: fill, t: {0, 0})

    {:ok, push_graph(scene, graph)}
  end

  @spec working(DateTime.t(), DateTime.t(), DateTime.t(), DateTime.t()) :: work_status()
  def working(now, start, partial, finish) do
    cond do
      # Before start of day and start time
      DateTime.compare(now, start) in [:lt, :eq] -> :no
      # After start time and before end of partial day
      DateTime.compare(now, partial) in [:lt, :eq] -> :yes
      # After end of partial day and before finish time
      DateTime.compare(now, finish) in [:lt, :eq] -> :partial
      # After finish time
      true -> :no
    end
  end
end
