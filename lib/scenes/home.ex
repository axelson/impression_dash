defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger
  import Scenic.Primitives

  alias Scenic.Graph
  alias ScenicWidgets.GraphTools
  alias ScenicContrib.Utils.GraphState

  @default_text_size 27
  @font Dash.font()

  defmodule State do
    @moduledoc false
    defstruct [:graph]
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    Process.register(self(), __MODULE__)
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())
    scale = Application.get_env(:dash, :scale, 1)

    graph =
      Graph.build(font: @font, font_size: @default_text_size, fill: :black, scale: scale)
      |> GraphTools.upsert(:bg, fn g ->
        render_background(g, scene.viewport, :white)
      end)
      |> render_time_text()
      # |> Dash.TextSize.add_to_graph(%{})
      # |> Dash.AvailableFonts.add_to_graph(%{})
      # Currently the inky impression doesn't fill the entire screen so I use
      # this green rectangle to remind me of the unprintable section
      |> rect({80, 480}, t: {720, 0}, fill: :green)

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
    Logger.info("Rendering updated weather results")

    scene =
      scene
      |> GraphState.update_graph(fn graph ->
        fetch_and_render_weather(graph, Dash.Locations.all())
        |> render_time_text()
      end)

    {:noreply, scene}
  end

  def handle_info(:refresh, scene) do
    Logger.info("Rendering updated scene via refresh")

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
    {open_prs_by_author, assigned_prs_by_author} = fetch_open_prs()

    locations
    |> Enum.map(fn location ->
      # Logger.info("fetching weather for location: #{inspect(location, pretty: true)}")
      case Dash.Weather.Server.get_weather(location) do
        {:ok, weather_result} ->
          # Logger.info("got weather_result: #{inspect(weather_result, pretty: true)}")
          {location, weather_result}

        # Is this bad?
        _ ->
          {location, nil}
      end
    end)
    |> Enum.with_index()
    |> Enum.reduce(graph, fn
      {{location, weather_result}, i}, graph ->
        y = 30 + i * 55

        render_weather_component(
          graph,
          location,
          weather_result,
          open_prs_by_author,
          assigned_prs_by_author,
          {15, y}
        )
        |> then(fn g ->
          # Don't show red bar on the last row (ez-mode)
          if location.name == "Home" do
            g
          else
            g
            |> rect({720, 1}, fill: :red, t: {0, y + 32})
          end
        end)
    end)
  end

  def fetch_open_prs() do
    case Dash.GhStats.fetch() do
      {:ok, rows} ->
        row = hd(rows)
        {row.num_prs_need_review_by_login, row.num_assigned_prs_by_login}

      {:error, _} ->
        {%{}, %{}}
    end
  end

  defp render_weather_component(
         graph,
         location,
         weather_result,
         open_prs_by_author,
         assigned_prs_by_author,
         transform
       ) do
    graph
    |> GraphTools.upsert(location.name, fn g ->
      Dash.WeatherResult.ScenicComponent.upsert(
        g,
        %{
          location: location,
          weather_result: weather_result,
          open_prs_by_author: open_prs_by_author,
          assigned_prs_by_author: assigned_prs_by_author,
        },
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
      text(g, time_str, id: :time, font: :unifont, font_size: 32, t: {540, 470})
    end)
  end
end
