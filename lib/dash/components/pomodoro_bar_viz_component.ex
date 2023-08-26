defmodule Dash.PomodoroBarVizComponent do
  use Scenic.Component
  use ScenicWidgets.GraphTools.Upsertable
  import Scenic.Primitives
  require Logger
  alias Scenic.Graph

  @width 546

  @impl Scenic.Component
  def validate(params) do
    {:ok, params}
  end

  @impl Scenic.Scene
  def init(scene, params, _opts) do
    case params[:stats] do
      {:ok, stats} ->
        graph = initialize_graph(stats)
        {:ok, push_graph(scene, graph)}

      {:error, _} ->
        graph = Graph.build()
        graph = text(graph, "No pomodoro data", fill: :black, font: :unifont, font_size: 16)
        {:ok, push_graph(scene, graph)}
    end
  end

  def initialize_graph(stats) do
    scale = Dash.Scale.new_continuous(domain: {5.5, 18.5}, range: {0, @width})
    scale_fn = Contex.Scale.domain_to_range_fn(scale)
    now = DateTime.now!("Pacific/Honolulu")

    graph =
      Graph.build()
      |> rect({@width, 1}, fill: :black, t: {0, 10})

    Enum.reduce(stats, graph, fn row, graph ->
      graph
      # work rect
      |> draw_rect(row.started_at, row.finished_at, scale_fn, :red)
      # limbo rect
      # TODO: Draw up to 15 minutes of limbo even if there's no rest time
      |> draw_rect(row.finished_at, row.rest_started_at, scale_fn, :orange)
      # rest rect
      |> draw_rect(row.rest_started_at, row.rest_finished_at, scale_fn, :blue)
    end)

    # 12 noon mark
    |> rect({2, 10}, fill: :black, t: {scale_fn.(12), 10})
    # current time
    |> rect({2, 10}, fill: :red, t: {scale_fn.(hour_min(now)), 10})
  end

  @impl GenServer
  def handle_info(msg, scene) do
    Logger.warning("Ignoring unhandled message: #{inspect(msg)}")
    {:noreply, scene}
  end

  def draw_rect(graph, start_time, finish_time, scale_fn, fill) do
    if start_time && finish_time do
      start_x = scale_fn.(hour_min(start_time))
      finish_x = scale_fn.(hour_min(finish_time))
      width = finish_x - start_x
      rect(graph, {width, 10}, t: {start_x, 0}, fill: fill)
    else
      graph
    end
  end

  def hour_min(%DateTime{} = time) do
    time.hour + time.minute / 60
  end
end
