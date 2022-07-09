defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger
  import Scenic.Primitives

  alias Scenic.Graph
  alias ScenicWidgets.Redraw
  alias ScenicWidgets.GraphState

  @text_size 24
  @default_quote "Inky Impression"

  defmodule State do
    @moduledoc false
    defstruct [:graph]
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())

    {width, height} = scene.viewport.size

    graph =
      Graph.build(font: :roboto, font_size: @text_size, fill: :black)
      |> rect({width, height}, fill: :white)
      |> Redraw.draw(:quote, fn g -> render_text(g, scene.viewport, @default_quote) end)

    state = %State{}
    scene = GraphState.assign_and_push_graph(scene, state, graph)

    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

  @impl GenServer
  def handle_info({:set_quote, text}, scene) do
    scene =
      GraphState.update_graph(scene, fn graph ->
        graph
        |> Redraw.draw(:quote, fn g -> render_text(g, scene.viewport, text) end)
      end)

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.info("Unhandled hande_info: #{inspect(msg)}")
    {:noreply, scene}
  end

  defp render_text(graph, viewport, text) do
    {width, _height} = viewport.size

    text(graph, text, id: :quote, translate: {width / 2, 120}, text_align: :center)
  end
end
