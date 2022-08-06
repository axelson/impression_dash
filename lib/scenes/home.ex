defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.Primitive
  alias ScenicWidgets.Redraw2
  alias ScenicWidgets.GraphState

  @default_text_size 32
  @font_metrics Dash.roboto_font_metrics()
  @default_quote "Inky Impression"

  defmodule State do
    @moduledoc false
    defstruct [:graph, :gh_stats_task_ref]
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())

    graph =
      Graph.build(font: :roboto, font_size: @default_text_size, fill: :black)
      |> Redraw2.draw(:bg, fn g ->
        render_background(g, scene.viewport, :white)
      end)
      |> Redraw2.draw(:quote, fn g ->
        render_text2(g, scene.viewport, @default_quote)
      end)
      |> Redraw2.draw(:sparkline, fn _g ->
        {Dash.Sparkline.ScenicComponent, %{}, t: {10, 10}}
      end)

    state = %State{}
    scene = GraphState.assign_and_push_graph(scene, state, graph)

    # WARN: This is a bit crappy because it'll cause the Inky Impression to redraw! Maybe it's reasonable though
    scene = fetch_gh_stats(scene)

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
        |> Redraw2.draw(:bg, fn g -> render_background(g, scene.viewport, bg_color) end)
        |> Redraw2.draw(:quote, fn g -> render_text2(g, scene.viewport, text) end)
      end)

    {:noreply, scene}
  end

  def handle_info({task_ref, {:task, task_result}}, scene) do
    scene =
      case {scene.assigns.state, task_result} do
        {%State{gh_stats_task_ref: ^task_ref}, {:fetch_gh_stats, rows}} ->
          data =
            Enum.map(rows, fn row -> row.num_prs_open end)
            |> Enum.chunk_every(1, 60)
            |> List.flatten()

          sparkline = Contex.Sparkline.new(data)
          dash_sparkline = Dash.Sparkline.parse(sparkline)

          Process.demonitor(task_ref, [:flush])

          GraphState.update_graph(scene, fn graph ->
            graph
            |> Redraw2.draw(:sparkline, fn _g ->
              {Dash.Sparkline.ScenicComponent, %{dash_sparkline: dash_sparkline}, []}
            end)
          end)
          |> assign(:task_ref, nil)

        _ ->
          Logger.warn("Unrecognized task ref: #{inspect(task_ref)}")
          scene
      end

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.info("Unhandled hande_info: #{inspect(msg)}")
    {:noreply, scene}
  end

  defp render_text2(_graph, viewport, text) when is_binary(text) do
    {width, _height} = viewport.size
    max_width = width * 3 / 4
    wrapped = FontMetrics.wrap(text, max_width, @default_text_size, @font_metrics)

    {Primitive.Text, wrapped,
     id: :quote, translate: {width / 2, 120}, text_align: :center, fill: :black}
  end

  defp render_background(_graph, viewport, bg_color) do
    {width, height} = viewport.size

    {Primitive.Rectangle, {width, height}, fill: bg_color}
  end

  defp fetch_gh_stats(scene) do
    task =
      Task.Supervisor.async_nolink(Dash.task_sup(), fn ->
        {:task, {:fetch_gh_stats, Dash.GhStats.run()}}
      end)

    state = %State{scene.assigns.state | gh_stats_task_ref: task.ref}

    assign(scene, :state, state)
  end
end
