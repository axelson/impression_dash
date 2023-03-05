defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger
  import Scenic.Primitives

  alias Scenic.Graph
  alias ScenicWidgets.GraphTools
  alias ScenicContrib.Utils.GraphState

  @default_text_size 27

  defmodule State do
    @moduledoc false
    defstruct [:graph]
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    Process.register(self(), __MODULE__)
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())

    graph =
      Graph.build(font: :roboto, font_size: @default_text_size, fill: :black)
      |> GraphTools.upsert(:bg, fn g ->
        render_background(g, scene.viewport, :white)
      end)

    graph =
      Enum.reduce(Enum.with_index(Dash.Locations.all()), graph, fn
        {location, i}, graph ->
          render_weather(graph, location, nil, {15, 260 + i * 75})
      end)

    state = %State{}

    scene =
      scene
      |> GraphState.assign_and_push_graph(state, graph)

    schedule_weather_update(:timer.minutes(0))

    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

  @impl GenServer
  def handle_info(:update_weather, scene) do
    scene =
      scene
      |> GraphState.update_graph(fn graph ->
        Enum.reduce(Enum.with_index(Dash.Locations.all()), graph, fn
          {location, i}, graph ->
            case Dash.Weather.Server.get_weather(location) do
              {:ok, weather_result} ->
                render_weather(graph, location, weather_result, {15, 260 + i * 75})

              error ->
                graph
            end
        end)
      end)

    schedule_weather_update(:timer.minutes(1))

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.info("Unhandled hande_info: #{inspect(msg)}")
    {:noreply, scene}
  end

  defp render_text(graph, viewport, text) when is_binary(text) do
    {width, _height} = viewport.size
    max_width = width * 3 / 4
    wrapped = FontMetrics.wrap(text, max_width, @default_text_size, font_metrics())

    text(graph, wrapped,
      translate: {width / 2, 220},
      text_align: :center,
      fill: :black
    )
  end

  defp render_weather(graph, location, weather_result, transform) do
    graph
    |> GraphTools.upsert(location.name, fn g ->
      Dash.WeatherResult.ScenicComponent.upsert(
        g,
        %{location: location, weather_result: weather_result},
        t: transform
      )
    end)
  end

  defp render_background(g, viewport, bg_color) do
    {width, height} = viewport.size

    rect(g, {width, height}, fill: bg_color)
  end

  defp schedule_weather_update(timeout) do
    Process.send_after(self(), :update_weather, timeout)
  end

  defp font_metrics do
    Dash.roboto_font_metrics()
  end
end
