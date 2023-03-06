defmodule PeriodicalScheduler do
  @moduledoc """
  Run code every 15 minutes
  """
  use GenServer
  require Logger
  @timeout 15000

  defmodule State do
    defstruct [:callbacks]
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_callback(callback) do
    GenServer.call(__MODULE__, {:register_callback, callback})
  end

  @impl GenServer
  def init(_) do
    state = %State{callbacks: []}

    if Application.fetch_env!(:dash, :wait_for_network) do
      result = VintageNet.subscribe(["interface", :_, "connection"])
      Logger.info("VintageNet subscribe: #{inspect(result)}")

      # PeriodicalScheduler unhandled msg: {VintageNet, ["interface", "wlan0", "connection"], :lan, :internet,

      receive do
        {VintageNet, ["interface", _, "connection"], :lan, :internet, _data} = msg ->
          Logger.info("Probably connected!!! #{inspect msg}")
      after
        @timeout ->
          Logger.info("No connection within #{@timeout} ms")
      end
    end

    schedule_work()

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:register_callback, callback}, _from, state) do
    state = %State{state | callbacks: [callback | state.callbacks]}
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    Logger.info("tick! #{inspect(Time.utc_now())}")

    Enum.each(state.callbacks, fn {dest, msg} ->
      send(dest, msg)
    end)


    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.info("PeriodicalScheduler unhandled msg: #{inspect(msg, pretty: true)}")
    {:noreply, state}
  end

  def seconds_till_next_tick(now \\ Time.utc_now()) do
    minutes = (14 - rem(now.minute, 15)) * 60
    seconds = 60 - now.second
    minutes + seconds
  end

  defp schedule_work() do
    next_ms = seconds_till_next_tick() * 1000
    IO.puts("Next tick in #{next_ms}")
    Process.send_after(self(), :tick, next_ms)
  end
end
