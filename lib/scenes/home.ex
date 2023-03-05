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

    graph = fetch_and_render_weather(graph, Dash.Locations.all())

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
        fetch_and_render_weather(graph, Dash.Locations.all())
      end)

    schedule_weather_update(:timer.minutes(1))

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.info("Unhandled hande_info: #{inspect(msg)}")
    {:noreply, scene}
  end

  defp fetch_and_render_weather(graph, locations) do
    locations
    |> Enum.map(fn location ->
      case Dash.Weather.Server.get_weather(location) do
        {:ok, weather_result} -> {location, weather_result}
        # Is this bad?
        _ -> {location, nil}
      end
    end)
    |> Enum.with_index()
    |> Enum.reduce(graph, fn
      {{location, weather_result}, i}, graph ->
        render_weather_component(graph, location, weather_result, {15, 260 + i * 75})
    end)
  end

  defp render_weather_component(graph, location, weather_result, transform) do
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
