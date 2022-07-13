defmodule Dash.Scene.ColorTest do
  use Scenic.Scene
  alias Scenic.Graph

  import Scenic.Primitives
  require Logger

  @graph Graph.build(fill: :black, font: :roboto)
         |> rectangle({600, 64}, t: {0, 64}, fill: :white)
         |> rectangle({600, 64}, t: {0, 128}, fill: :green)
         |> rectangle({600, 64}, t: {0, 192}, fill: :blue)
         |> rectangle({600, 64}, t: {0, 256}, fill: :red)
         |> rectangle({600, 64}, t: {0, 320}, fill: :yellow)
         |> rectangle({600, 64}, t: {0, 384}, fill: :orange)
         |> text("Black", font_size: 36, t: {24, 38}, fill: :white)
         |> text("White", font_size: 36, t: {24, 102}, fill: :black)
         |> text("Green", font_size: 36, t: {24, 166}, fill: :white)
         |> text("Blue", font_size: 36, t: {24, 230}, fill: :white)
         |> text("Red", font_size: 36, t: {24, 294}, fill: :white)
         |> text("Yellow", font_size: 36, t: {24, 358}, fill: :black)
         |> text("Orange", font_size: 36, t: {24, 422}, fill: :white)

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    state = %{graph: @graph}
    Logger.info("Started :mainscene")

    Process.register(self(), :mainscene)
    scene = assign(scene, :state, state)
    scene = push_graph(scene, @graph)
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
