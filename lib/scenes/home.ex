defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger
  import Scenic.Primitives

  alias Scenic.Graph
  alias ScenicWidgets.GraphTools
  alias ScenicContrib.Utils.GraphState

  @default_text_size 27
  @default_quote "Inky Impression"

  %Dash.GhStats.Row{
    inserted_at: ~N[2022-08-06 21:48:01],
    num_outstanding_review_requests: 80,
    num_prs_approved_not_merged: 9,
    num_prs_needs_review: 11,
    num_prs_open: 40,
  }

  @sparklines [
                {:num_outstanding_review_requests, "Review Requests"},
                {:num_prs_approved_not_merged, "Approved !Merged"},
                {:num_prs_needs_review, "Needs Review"},
                {:num_prs_open, "Open"},
              ]
              |> Enum.map(fn {id, label} ->
                label_id = "sparkline_label_#{id}" |> String.to_atom()
                sparkline_id = "sparkline_#{id}" |> String.to_atom()

                %{
                  id: id,
                  sparkline_id: sparkline_id,
                  label: label,
                  label_id: label_id,
                }
              end)

  defmodule State do
    @moduledoc false
    defstruct [:graph, :gh_stats_task_ref]
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    Process.register(self(), __MODULE__)
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())

    sparkline_base = 10
    sparkline_spacing = 50
    sparkline_y = fn i -> sparkline_base + sparkline_spacing * i end

    location = Dash.Locations.all() |> hd()
    IO.inspect(location, label: "location (home.ex:54)")

    graph =
      Graph.build(font: :roboto, font_size: @default_text_size, fill: :black)
      |> GraphTools.upsert(:bg, fn g ->
        render_background(g, scene.viewport, :white)
      end)
      |> GraphTools.upsert(:quote, fn g ->
        render_text(g, scene.viewport, @default_quote)
      end)

    # |> GraphTools.upsert(:honolulu, fn g ->
    #  Dash.WeatherResult.ScenicComponent.upsert(g, %{location: location}, t: {15, 320})
    # end)

    # |> GraphTools.upsert(:honolulu, fn g ->
    #   {width, _height} = scene.viewport.size
    #   max_width = width * 3 / 4
    #   wrapped = FontMetrics.wrap("Honolulu", max_width, @default_text_size, font_metrics())

    #   text(g, wrapped,
    #     translate: {15, 320},
    #     text_align: :left,
    #     fill: :black
    #   )
    # end)

    graph =
      Enum.reduce(Enum.with_index(Dash.Locations.all()), graph, fn
        {location, i}, graph ->
          graph
          |> GraphTools.upsert(location.name, fn g ->
            Dash.WeatherResult.ScenicComponent.upsert(g, %{location: location},
              t: {15, 320 + i * 75}
            )
          end)
      end)

    graph =
      Enum.reduce(Enum.with_index(@sparklines), graph, fn
        {%{sparkline_id: sparkline_id, label: label, label_id: label_id}, i}, graph ->
          graph
          |> GraphTools.upsert(label_id, fn g ->
            text(g, label, t: {90, sparkline_y.(i) + 15}, font_size: 10, text_align: :right)
          end)
          |> GraphTools.upsert(sparkline_id, fn g ->
            Dash.Sparkline.ScenicComponent.upsert(g, %{}, t: {95, sparkline_y.(i)})
            # {Dash.Sparkline.ScenicComponent, %{}, t: {95, sparkline_y.(i)}}
          end)
      end)

    state = %State{}

    scene =
      scene
      # |> fetch_gh_stats(scene)
      |> GraphState.assign_and_push_graph(state, graph)

    # WARN: This is a bit crappy because it'll cause the Inky Impression to redraw! Maybe it's reasonable though
    scene = async_fetch_gh_stats(scene)

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
        |> GraphTools.upsert(:bg, fn g -> render_background(g, scene.viewport, bg_color) end)
        |> GraphTools.upsert(:quote, fn g -> render_text(g, scene.viewport, text) end)
      end)

    {:noreply, scene}
  end

  def handle_info(:update_stats, scene) do
    scene = async_fetch_gh_stats(scene)
    {:noreply, scene}
  end

  def handle_info({task_ref, {:task, task_result}}, scene) do
    # Logger.debug("task_result: #{inspect(task_result, pretty: true)}")

    scene =
      case {scene.assigns.state, task_result} do
        {%State{gh_stats_task_ref: ^task_ref}, {:fetch_gh_stats, rows}} ->
          Logger.info("Redrawing with new stats")
          Process.demonitor(task_ref, [:flush])

          scene
          |> GraphState.update_state(fn state -> %State{state | gh_stats_task_ref: nil} end)
          |> GraphState.update_graph(fn graph ->
            Enum.reduce(@sparklines, graph, fn %{id: id, sparkline_id: sparkline_id}, graph ->
              graph
              |> GraphTools.upsert(sparkline_id, fn g ->
                sparkline = prepare_data(rows, id)
                Dash.Sparkline.ScenicComponent.upsert(g, %{dash_sparkline: sparkline}, [])
              end)
            end)
          end)

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

  defp render_text(graph, viewport, text) when is_binary(text) do
    {width, _height} = viewport.size
    max_width = width * 3 / 4
    wrapped = FontMetrics.wrap(text, max_width, @default_text_size, font_metrics())

    text(graph, wrapped,
      translate: {width / 2, 220},
      text_align: :center,
      fill: :black
    )
  end

  defp render_background(g, viewport, bg_color) do
    {width, height} = viewport.size

    rect(g, {width, height}, fill: bg_color)
  end

  defp async_fetch_gh_stats(scene) do
    Logger.info("Fetching gh_stats")

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

    sparkline =
      Contex.Sparkline.new(data)
      |> Contex.Sparkline.colours("rgba(255, 0, 0, 1)", "rgba(255, 0, 0, 1)")

    # |> Contex.Sparkline.

    Logger.info("prep sparkline")

    Dash.Sparkline.parse(sparkline)
  end

  defp font_metrics do
    Dash.roboto_font_metrics()
  end
end
