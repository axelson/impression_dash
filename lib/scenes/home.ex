defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.Primitive
  alias ScenicWidgets.Redraw2
  alias ScenicWidgets.GraphState

  @default_text_size 27
  @font_metrics Dash.roboto_font_metrics()
  @default_quote "Inky Impression"

  %Dash.GhStats.Row{
    inserted_at: ~N[2022-08-06 21:48:01],
    num_outstanding_review_requests: 80,
    num_prs_approved_not_merged: 9,
    num_prs_needs_review: 11,
    num_prs_open: 40
  }

  @sparklines [
                {:num_outstanding_review_requests, "Review Requests"},
                {:num_prs_approved_not_merged, "Approved !Merged"},
                {:num_prs_needs_review, "Needs Review"},
                {:num_prs_open, "Open"}
              ]
              |> Enum.map(fn {id, label} ->
                label_id = "sparkline_label_#{id}" |> String.to_atom()
                sparkline_id = "sparkline_#{id}" |> String.to_atom()

                %{
                  id: id,
                  sparkline_id: sparkline_id,
                  label: label,
                  label_id: label_id
                }
              end)

  defmodule State do
    @moduledoc false
    defstruct [:graph, :gh_stats_task_ref]
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())

    sparkline_base = 10
    sparkline_spacing = 40
    sparkline_y = fn i -> sparkline_base + sparkline_spacing * i end

    graph =
      Graph.build(font: :roboto, font_size: @default_text_size, fill: :black)
      |> Redraw2.draw(:bg, fn g ->
        render_background(g, scene.viewport, :white)
      end)
      |> Redraw2.draw(:quote, fn g ->
        render_text2(g, scene.viewport, @default_quote)
      end)

    graph =
      Enum.reduce(Enum.with_index(@sparklines), graph, fn
        {%{sparkline_id: sparkline_id, label: label, label_id: label_id}, i}, graph ->
          graph
          |> Redraw2.draw(label_id, fn _g ->
            {Primitive.Text, label, t: {90, sparkline_y.(i) + 15}, font_size: 10, text_align: :right}
          end)
          |> Redraw2.draw(sparkline_id, fn _g ->
            {Dash.Sparkline.ScenicComponent, %{}, t: {95, sparkline_y.(i)}}
          end)
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
          Process.demonitor(task_ref, [:flush])

          GraphState.update_graph(scene, fn graph ->
            Enum.reduce(@sparklines, graph, fn %{id: id, sparkline_id: sparkline_id}, graph ->
              graph
              |> Redraw2.draw(sparkline_id, fn _g ->
                sparkline = prepare_data(rows, id)
                {Dash.Sparkline.ScenicComponent, %{dash_sparkline: sparkline}, []}
              end)
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
     id: :quote, translate: {width / 2, 220}, text_align: :center, fill: :black}
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

  defp prepare_data(rows, column) do
    data =
      Enum.map(rows, fn row -> Map.get(row, column) end)
      |> Enum.chunk_every(1, 60)
      |> List.flatten()

    sparkline = Contex.Sparkline.new(data)
    Dash.Sparkline.parse(sparkline)
  end
end
