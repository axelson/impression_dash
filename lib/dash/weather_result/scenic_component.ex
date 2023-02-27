defmodule Dash.WeatherResult.ScenicComponent do
  use Scenic.Component
  use ScenicWidgets.GraphTools.Upsertable
  use TypedStruct
  import Scenic.Primitives
  require Logger

  alias Scenic.Graph
  alias ScenicContrib.Utils.GraphState
  alias ScenicWidgets.GraphTools

  typedstruct module: State do
    field :graph, Scenic.Graph.t()
    field :location, Dash.Location.t()
    field :weather_result, Dash.WeatherResult.t()
  end

  @impl Scenic.Component
  def validate(params), do: {:ok, params}

  @impl Scenic.Scene
  def init(scene, params, _opts) do
    graph = Graph.build()
    %{location: location} = params

    state = %State{location: location}

    scene = GraphState.assign_and_push_graph(scene, state, graph)

    scene =
      GraphState.update_graph(scene, fn graph ->
        graph
        |> GraphTools.upsert(:name, fn g -> text(g, location.name, fill: :black) end)
        |> GraphTools.upsert(:location_name, fn g ->
          text(g, location.location_name, fill: :black, t: {0, 20}, font_size: 14)
        end)
      end)

    self = self()

    # This is lazy, proper supervision would be better
    Task.start(fn ->
      send(self, {:weather_result, Dash.Weather.request(location)})
    end)

    {:ok, scene}
  end

  # Unecessary duplication
  # def upsert(graph_or_primitive, data, opts) do
  #   case graph_or_primitive do
  #     %Scenic.Graph{} = graph -> add_to_graph(graph, data, opts)
  #     # What modify function is this currently calling???
  #     %Scenic.Primitive{} = primitive -> modify(primitive, data, opts)
  #   end
  # end

  @impl GenServer
  def handle_info({:weather_result, weather_result}, scene) do
    Logger.info("weather_result: #{inspect(weather_result, pretty: true)}")

    scene =
      GraphState.update_graph(scene, fn graph ->
        graph
        |> GraphTools.upsert(:summary, fn g ->
          text(g, weather_result.summary, fill: :black, t: {150, 0})
        end)
        |> GraphTools.upsert(:temperature, fn g ->
          text(g, to_string(weather_result.temperature), fill: :black, t: {150, 25})
        end)
      end)

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.warn("Ignoring unhandled message: #{inspect(msg)}")
    {:noreply, scene}
  end
end
