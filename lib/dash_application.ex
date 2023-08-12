defmodule DashApplication do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    main_viewport_config = Application.get_env(:dash, :viewport)

    children =
      [
        Dash.Repo,
        Dash.QuantumScheduler,
        {Dash.Weather.Server, locations: Application.fetch_env!(:dash, :locations)},
        {Phoenix.PubSub, name: Dash.pub_sub()},
        {Task.Supervisor, name: Dash.task_sup()},
        if main_viewport_config do
          {Scenic, [main_viewport_config]}
        else
          []
        end,
      ]
      |> List.flatten()

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
