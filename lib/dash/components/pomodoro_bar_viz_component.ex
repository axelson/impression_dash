defmodule Dash.PomodoroBarVizComponent do
  use Scenic.Component
  use ScenicWidgets.GraphTools.Upsertable
  import Scenic.Primitives
  require Logger
  alias Scenic.Graph

  @width 546

  # I have the component fetch its own params because all the state that the
  # component needs shoudl be encapsulated here. Otherwise when the component is
  # upserted if the params are the same, no new render will happen
  def fetch_params do
    %{
      stats: get_pomodoro_stats(),
      now: DateTime.now!(Dash.timezone()),
    }
  end

  @impl Scenic.Component
  def validate(params) do
    {:ok, params}
  end

  @impl Scenic.Scene
  def init(scene, params, _opts) do
    now = params[:now]

    case params[:stats] do
      {:ok, [_ | _] = stats} ->
        graph = initialize_graph(stats, now)
        {:ok, push_graph(scene, graph)}

      {:ok, []} ->
        graph = Graph.build()
        graph = text(graph, "Empty pomodoro data!", fill: :black, font: :unifont, font_size: 16)
        {:ok, push_graph(scene, graph)}

      {:error, error} ->
        Logger.warning("pomodoro stats error: #{inspect(error, pretty: true)}")
        graph = Graph.build()
        graph = text(graph, "No pomodoro data!", fill: :black, font: :unifont, font_size: 16)
        {:ok, push_graph(scene, graph)}
    end
  end

  def initialize_graph(pomodoros, now) do
    # scale = Dash.Scale.new_continuous(domain: {7.5, 20.5}, range: {0, @width})
    scale = Dash.Scale.new_continuous(domain: {6.5, 20.5}, range: {0, @width})
    scale_fn = Contex.Scale.domain_to_range_fn(scale)

    graph =
      Graph.build()
      |> rect({@width, 1}, fill: :black, t: {0, 10})

    Enum.reduce(pomodoros, graph, fn pomodoro, graph ->
      graph
      # work-time rectangle
      |> draw_rect(pomodoro.started_at, pomodoro.finished_at, scale_fn, :red)
      # limbo-time rectangle
      |> draw_rect(pomodoro.finished_at, pomodoro.rest_started_at, scale_fn, :orange)
      # rest-time rectangle
      |> draw_rect(pomodoro.rest_started_at, pomodoro.rest_finished_at, scale_fn, :blue)
    end)
    # 12 noon mark
    |> rect({2, 10}, fill: :black, t: {scale_fn.(12), 10})
    # current time
    |> rect({2, 10}, fill: :red, t: {scale_fn.(hour_min(now)), 10})
    |> text(:erlang.float_to_binary(total_hours(pomodoros), decimals: 1),
      fill: :black,
      t: {@width + 3, 0},
      font: :unifont,
      font_size: 16,
      text_base: :top
    )
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

  def total_hours(pomodoros) do
    pomodoros
    |> Enum.map(&pomodoro_length/1)
    |> Enum.sum()
  end

  def pomodoro_length(pomodoro) do
    start_time = hour_min(pomodoro.started_at)

    finish_time =
      cond do
        pomodoro.rest_finished_at -> pomodoro.rest_finished_at
        pomodoro.rest_started_at -> pomodoro.rest_started_at
        pomodoro.finished_at -> pomodoro.finished_at
        true -> pomodoro.started_at
      end
      |> hour_min()

    finish_time - start_time
  end

  def get_pomodoro_stats do
    try do
      Dash.PomodoroServer.get_stats()
      |> tap(fn stats ->
        Logger.info("fetched pomodoro stats: #{inspect(stats, pretty: true)}")
      end)

      # stats =
      #   Dash.PomodoroParser.sample_csv()
      #   |> Dash.PomodoroParser.parse()

      # {:ok, stats}
    catch
      :exit, _ ->
        Logger.warning("Unable to fetch pomodoro stats because of `:exit`")
        {:error, :unable_to_fetch_stats}
    end
  end
end
