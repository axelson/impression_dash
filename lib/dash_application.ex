defmodule DashApplication do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    main_viewport_config = Application.get_env(:dash, :viewport)

    children = [
      Dash.Repo,
      {Phoenix.PubSub, name: Dash.pub_sub()},
      {Task.Supervisor, name: Dash.task_sup()},
      {Scenic, [main_viewport_config]},
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
