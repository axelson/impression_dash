defmodule PeriodicalScheduler do
  @moduledoc """
  Run code every 15 minutes
  """
  use GenServer
  require Logger

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
    Logger.info("tick! #{inspect Time.utc_now()}")

    Enum.each(state.callbacks, fn {dest, msg} ->
      send(dest, msg)
    end)

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
