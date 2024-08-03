defmodule DashApplication do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    children =
      [
        Dash.Repo,
        {Phoenix.PubSub, name: Dash.pub_sub()},
        Dash.PomodoroServer,
        Dash.QuantumScheduler,
        maybe_start(
          {Dash.Weather.Server, locations: Application.fetch_env!(:dash, :locations)},
          Application.get_env(:dash, :start_weather_server, true)
        ),
        {Task.Supervisor, name: Dash.task_sup()},
        maybe_start_scenic(),
      ]
      |> List.flatten()

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp maybe_start(_child, false), do: []
  defp maybe_start(child, true), do: child

  defp maybe_start_scenic do
    main_viewport_config = Application.get_env(:dash, :viewport)

    if main_viewport_config do
      {Scenic, [main_viewport_config]}
    else
      []
    end
  end
end
