defmodule Dash.PomodoroServer do
  use GenServer
  require Logger

  defmodule State do
    use TypedStruct

    typedstruct do
      field :rows, map()
    end
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def refresh do
    GenServer.call(__MODULE__, :refresh, 30_000)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl GenServer
  def init(_opts) do
    state = %State{rows: []}
    {:ok, state, {:continue, nil}}
  end

  @impl GenServer
  def handle_continue(_, state) do
    state = do_refresh(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:refresh, _from, state) do
    state = do_refresh(state)
    {:reply, :ok, state}
  end

  def handle_call(:get_stats, _from, state) do
    # {:reply, {:ok, Dash.PomodoroSampleData.sample}, state}
    {:reply, {:ok, state.rows}, state}
  end

  def do_refresh(state) do
    case Req.get("http://pomodoro.nerves-side-screen.local/api/stats.csv", max_retries: 2) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        rows = Dash.PomodoroParser.parse(body)
        %{state | rows: rows}

      err ->
        Logger.warning("Unable to fetch pomodoro stats: #{inspect(err)}")
        state
    end
  end
end
