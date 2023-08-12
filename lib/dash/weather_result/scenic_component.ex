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

  @font Dash.font()

  @impl Scenic.Component
  def validate(params), do: {:ok, params}

  @impl Scenic.Scene
  def init(scene, params, _opts) do
    graph = Graph.build(font: @font)

    %{
      location: location,
      weather_result: weather_result,
      open_prs_by_author: open_prs_by_author,
    } = params

    state = %State{location: location}

    scene = GraphState.assign_and_push_graph(scene, state, graph)

    scene =
      GraphState.update_graph(scene, fn graph ->
        graph =
          graph
          |> GraphTools.upsert(:name, fn g ->
            text(g, location.name, fill: :black, font: :adventures, font_size: 14)
          end)
          |> GraphTools.upsert(:location_name, fn g ->
            text(g, location.location_name,
              fill: :black,
              t: {0, 20},
              font: :unifont,
              font_size: 16
            )
          end)

        if weather_result do
          graph
          |> GraphTools.upsert(:summary, fn g ->
            text(g, weather_text(weather_result.summary),
              fill: :black,
              font: :unifont,
              font_size: 16,
              t: {150, 0}
            )
          end)
          |> GraphTools.upsert(:temperature, fn g ->
            fahrenheit = weather_result.temperature
            celsius = Dash.WeatherResult.fahrenheit_to_celsius(fahrenheit)

            temperature_str = "#{round(celsius)}/#{round(fahrenheit)}°"

            text(g, to_string(temperature_str),
              fill: :black,
              font: :unifont,
              font_size: 16,
              t: {150, 20}
            )
          end)
          |> GraphTools.upsert(:time_text, fn g ->
            text(g, time_text(location.tz),
              id: :time_text,
              fill: :black,
              font: :unifont,
              font_size: 16,
              t: {265, 0}
            )
          end)
          |> GraphTools.upsert(:work_status, fn g ->
            Dash.Components.WorkStatusComponent.add_to_graph(
              g,
              %{
                start_time: location.start_time,
                partial_finish_time: location.partial_finish_time,
                finish_time: location.finish_time,
                tz: location.tz,
              },
              t: {255, -5}
            )
          end)
          |> GraphTools.upsert(:num_open_prs_text, fn g ->
            num_open_prs = open_prs_by_author[location.gh_login] || 0

            text =
              if num_open_prs > 0 do
                "#{num_open_prs} needs review"
              else
                ""
              end

            text(g, text,
              id: :num_open_prs_text,
              fill: :black,
              font: :unifont,
              font_size: 16,
              t: {249, 15}
            )
          end)
          # I've had some issues putting other things after the icon
          |> GraphTools.upsert(:icon, fn g ->
            icon = weather_icon(weather_result.icon)

            sprites(
              g,
              {{:dash, "icons/" <> icon}, [{{0, 0}, {512, 512}, {210, -10}, {30, 30}}]}
            )
          end)
        else
          graph
        end
      end)

    # self = self()

    # This is lazy, proper supervision would be better
    # Task.start(fn ->
    #   case Dash.Weather.Server.get_weather(location) do
    #     {:ok, weather_result} -> send(self, {:weather_result, weather_result})
    #     error -> Logger.warning("Failed to retrieve weather: #{inspect(error)}")
    #   end

    #   # case Dash.Weather.request(location) do
    #   #   {:ok, weather_result} -> send(self, {:weather_result, weather_result})
    #   #   error -> Logger.warning("Failed to retrieve weather: #{inspect(error)}")
    #   # end
    # end)

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
    Logger.warning("Ignoring unhandled message: #{inspect(msg)}")
    {:noreply, scene}
  end

  def weather_text(text) do
    case text do
      "Partly Cloudy" -> "Pt. Cld"
      text -> text
    end
  end

  def weather_icon(icon) do
    case icon do
      "cloudy" -> "cloud.png"
      "lightning" -> "lightning.png"
      # ???
      "mist" -> "mist.png"
      "clear-night" -> "night.png"
      "partly-cloudy-night" -> "partly_cloudy.png"
      "partly-cloudy-day" -> "partly_cloudy.png"
      "rain" -> "rain.png"
      # ???
      "sleet" -> "sleet.png"
      "snowing" -> "snowflake.png"
      # ??
      "sunny" -> "sunny.png"
      "clear-day" -> "sun.png"
      "sun" -> "sun.png"
      "wind" -> "wind.png"
      other -> default_icon(other)
    end
  end

  defp default_icon(other) do
    Logger.warning("Icon #{inspect(other)} not recognized")
    "question_mark.png"
  end

  def time_text(nil), do: "missing"

  def time_text(tz) do
    DateTime.now!(tz)
    |> Calendar.strftime("%H:%M")
  end
end
