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
      |> render_time_text()

    graph = fetch_and_render_weather(graph, Dash.Locations.all())

    state = %State{}

    scene =
      scene
      |> GraphState.assign_and_push_graph(state, graph)

    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

  @impl GenServer
  def handle_info({:updated_weather_results, _weather_results}, scene) do
    Logger.info("Updating weather!")

    scene =
      scene
      |> GraphState.update_graph(fn graph ->
        fetch_and_render_weather(graph, Dash.Locations.all())
        |> render_time_text()
      end)

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.info("Unhandled handle_info: #{inspect(msg)}")
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
        render_weather_component(graph, location, weather_result, {15, 30 + i * 75})
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

  defp render_time_text(g) do
    now =
      DateTime.now!("Pacific/Honolulu")
      # The display takes about 30 seconds to fully refresh so adjust the rendered time to match
      |> DateTime.add(30, :second)

    time_str = Calendar.strftime(now, "%m/%d %H:%M")

    g
    |> GraphTools.upsert(:time, fn g ->
      text(g, time_str, id: :time, t: {440, 430})
    end)
  end
end
