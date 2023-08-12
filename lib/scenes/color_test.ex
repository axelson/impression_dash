defmodule Dash.Scene.ColorTest do
  use Scenic.Scene
  alias Scenic.Graph

  import Scenic.Primitives
  require Logger

  defp initial_graph(%Scenic.ViewPort{size: {width, height}}) do
    spacing = div(height, 7)
    text_spacer = -46

    Graph.build(fill: :black, font: :roboto)
    |> rectangle({width, spacing}, t: {0, spacing * 0}, fill: :black)
    |> rectangle({width, spacing}, t: {0, spacing * 1}, fill: :white)
    |> rectangle({width, spacing}, t: {0, spacing * 2}, fill: :green)
    |> rectangle({width, spacing}, t: {0, spacing * 3}, fill: :blue)
    |> rectangle({width, spacing}, t: {0, spacing * 4}, fill: :red)
    |> rectangle({width, spacing}, t: {0, spacing * 5}, fill: :yellow)
    |> rectangle({width, spacing}, t: {0, spacing * 6}, fill: :orange)
    |> text("Black", font_size: 36, t: {24, spacing * 0 - text_spacer}, fill: :white)
    |> text("White", font_size: 36, t: {24, spacing * 1 - text_spacer}, fill: :black)
    |> text("Green", font_size: 36, t: {24, spacing * 2 - text_spacer}, fill: :white)
    |> text("Blue", font_size: 36, t: {24, spacing * 3 - text_spacer}, fill: :white)
    |> text("Red", font_size: 36, t: {24, spacing * 4 - text_spacer}, fill: :white)
    |> text("Yellow", font_size: 36, t: {24, spacing * 5 - text_spacer}, fill: :black)
    |> text("Orange", font_size: 36, t: {24, spacing * 6 - text_spacer}, fill: :white)
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    state = %{graph: initial_graph(scene.viewport)}
    Logger.info("Started :mainscene")

    Process.register(self(), :mainscene)
    scene = assign(scene, :state, state)
    scene = push_graph(scene, state.graph)
    {:ok, scene}
  end

  @impl GenServer
  def handle_info({:update, message}, scene) do
    if message !== nil do
      graph =
        Graph.build(fill: :black, font: :roboto, theme: :light)
        |> rectangle({600, 448}, fill: :white)
        |> text(message, font_size: 72, t: {100, 100})

      state = %{scene.assigns.state | graph: graph}
      scene = push_graph(scene, graph)
      scene = assign(scene, :state, state)

      {:noreply, scene}
    else
      {:noreply, scene}
    end
  end
end
