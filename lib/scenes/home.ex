defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger
  import Scenic.Primitives

  alias Scenic.Graph
  alias ScenicWidgets.Redraw
  alias ScenicWidgets.GraphState

  @default_text_size 32
  @font_metrics Dash.roboto_font_metrics()
  @default_quote "Inky Impression"

  defmodule State do
    @moduledoc false
    defstruct [:graph]
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())

    graph =
      Graph.build(font: :roboto, font_size: @default_text_size, fill: :black)
      |> render_background(scene.viewport, :white)
      |> render_text(scene.viewport, @default_quote)
      |> Redraw.draw(:sparkline, fn g ->
        Dash.Sparkline.ScenicComponent.add_to_graph(g, nil, t: {10, 10})
      end)

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
  def handle_info({:set_quote, text, bg_color}, scene) do
    scene =
      GraphState.update_graph(scene, fn graph ->
        graph
        |> Redraw.draw(:bg, fn g -> render_background(g, scene.viewport, bg_color) end)
        |> Redraw.draw(:quote, fn g -> render_text(g, scene.viewport, text) end)
      end)

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.info("Unhandled hande_info: #{inspect(msg)}")
    {:noreply, scene}
  end

  defp render_text(graph, viewport, text) when is_binary(text) do
    {width, _height} = viewport.size
    max_width = width * 3 / 4
    wrapped = FontMetrics.wrap(text, max_width, @default_text_size, @font_metrics)

    text(graph, wrapped,
      id: :quote,
      translate: {width / 2, 120},
      text_align: :center,
      fill: :black
    )
  end

  defp render_background(graph, viewport, bg_color) do
    {width, height} = viewport.size

    rect(graph, {width, height}, id: :bg, fill: bg_color)
  end
end
