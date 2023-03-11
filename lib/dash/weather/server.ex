defmodule Dash.Weather.Server do
  use GenServer
  require Logger

  defmodule State do
    use TypedStruct

    typedstruct do
      field :locations, [Dash.Location.t()]
      # TODO: Key this by latlon instead?
      field :weather_results, %{Dash.Location.t() => Dash.WeatherResult.t()}
    end
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_weather(location) do
    GenServer.call(__MODULE__, {:get_weather, location})
  end

  def broadcast() do
    GenServer.call(__MODULE__, :broadcast)
  end

  def init(opts \\ []) do
    locations = Keyword.get(opts, :locations, [])

    state = %State{
      locations: locations,
      weather_results: %{},
    }

    PeriodicalScheduler.register_callback({self(), :update_weather})
    send(self(), :update_weather)

    {:ok, state}
  end

  def handle_call({:get_weather, location}, _from, state) do
    %State{weather_results: weather_results} = state
    result = Map.fetch(weather_results, location)
    {:reply, result, state}
  end

  def handle_call(:broadcast, _from, state) do
    broadcast_results(state.weather_results)
    {:reply, :ok, state}
  end

  def handle_info(:update_weather, state) do
    results =
      Task.Supervisor.async_stream_nolink(
        Dash.task_sup(),
        state.locations,
        fn location ->
          case fetch_weather(location) do
            {:ok, weather_result} -> {location, weather_result}
            error -> error
          end
        end,
        ordered: false,
        max_concurrency: 15,
        timeout: :timer.seconds(30)
      )
      |> Enum.to_list()

    weather_results =
      Enum.reduce(results, state.weather_results, fn
        {:ok, {location, weather_result}}, weather_results ->
          Map.put(weather_results, location, weather_result)

        _, weather_results ->
          weather_results
      end)

    broadcast_results(weather_results)

    state = %State{state | weather_results: weather_results}

    {:noreply, state}
  end

  defp broadcast_results(weather_results) do
    Phoenix.PubSub.broadcast(Dash.pub_sub(), Dash.topic(), {:updated_weather_results, weather_results})
  end

  defp fetch_weather(location) do
    Logger.info("Fetching weather for #{location.name}")

    case Dash.Weather.request(location) do
      {:ok, weather_result} -> {:ok, weather_result}
      error -> Logger.warn("Failed to retrieve weather: #{inspect(error)}")
    end
  end
end
