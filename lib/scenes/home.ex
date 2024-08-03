defmodule Dash.Scene.Home do
  use Scenic.Scene
  require Logger
  import Scenic.Primitives

  alias Scenic.Graph
  alias ScenicWidgets.GraphTools
  alias ScenicContrib.Utils.GraphState

  @default_text_size 27
  @font Dash.font()

  defmodule State do
    @moduledoc false
    defstruct [:graph]
  end

  def refresh do
    Phoenix.PubSub.broadcast(
      Dash.pub_sub(),
      Dash.topic(),
      :refresh
    )
  end

  def switch_quotes do
    Phoenix.PubSub.broadcast(
      Dash.pub_sub(),
      Dash.topic(),
      :switch_quotes
    )
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    Process.register(self(), __MODULE__)
    :ok = Phoenix.PubSub.subscribe(Dash.pub_sub(), Dash.topic())
    scale = Application.get_env(:dash, :scale, 1)

    quote = Dash.Trello.random_quote()
    commitment = Dash.Commitments.random_commitment()

    graph =
      Graph.build(font: @font, font_size: @default_text_size, scale: scale)
      # Graph.build(font: @font, font_size: @default_text_size, fill: :black, scale: scale)
      |> GraphTools.upsert(:bg, fn g ->
        render_background(g, scene.viewport, :white)
      end)
      |> render_time_text()
      |> render_quote_text(quote.text)
      |> render_commitment_text(commitment)
      |> render_calendar()
      |> render_pomodoro()

    # |> Dash.TextSize.add_to_graph(%{})
    # |> Dash.AvailableFonts.add_to_graph(%{})

    graph = fetch_and_render_weather(graph, Dash.Locations.all())

    state = %State{}

    scene =
      scene
      |> GraphState.assign_and_push_graph(state, graph)

    Logger.info("JAX #{__MODULE__} init/3 complete")
    {:ok, scene}
  end

  @impl Scenic.Scene
  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

  @impl GenServer
  def handle_info({:updated_weather_results, _weather_results}, scene) do
    Logger.info("Rendering updated weather results")

    scene =
      scene
      |> GraphState.update_graph(fn graph ->
        fetch_and_render_weather(graph, Dash.Locations.all())
        |> render_time_text()
      end)

    {:noreply, scene}
  end

  def handle_info(:refresh, scene) do
    Logger.info("Rendering updated scene via refresh")

    quote = Dash.Trello.random_quote()

    scene =
      scene
      |> GraphState.update_graph(fn graph ->
        fetch_and_render_weather(graph, Dash.Locations.all())
        |> render_time_text()
        |> render_quote_text(quote.text)
        |> render_calendar()
        |> render_pomodoro()
      end)

    {:noreply, scene}
  end

  def handle_info(:switch_quotes, scene) do
    quote = Dash.Trello.random_quote()
    commitment = Dash.Commitments.random_commitment()

    scene =
      scene
      |> GraphState.update_graph(fn graph ->
        graph
        |> render_quote_text(quote.text)
        |> render_commitment_text(commitment)
      end)

    {:noreply, scene}
  end

  def handle_info({:set_quote, text}, scene) do
    Logger.info("Setting quote to: #{inspect(text)}")

    scene =
      scene
      |> GraphState.update_graph(fn graph ->
        render_quote_text(graph, text)
      end)

    {:noreply, scene}
  end

  def handle_info(msg, scene) do
    Logger.info("Unhandled handle_info: #{inspect(msg)}")
    {:noreply, scene}
  end

  defp fetch_and_render_weather(graph, locations) do
    {open_prs_by_author, assigned_prs_by_author} = fetch_open_prs()

    locations
    |> Enum.map(fn location ->
      # Logger.info("fetching weather for location: #{inspect(location, pretty: true)}")
      case Dash.Weather.Server.get_weather(location) do
        {:ok, weather_result} ->
          # Logger.info("got weather_result: #{inspect(weather_result, pretty: true)}")
          {location, weather_result}

        # Is this bad?
        _ ->
          {location, nil}
      end
    end)
    |> Enum.with_index()
    |> Enum.reduce(graph, fn
      {{location, weather_result}, i}, graph ->
        y = 30 + i * 55

        render_weather_component(
          graph,
          location,
          weather_result,
          open_prs_by_author,
          assigned_prs_by_author,
          {15, y}
        )
        |> then(fn g ->
          # Don't show red bar on the last row (ez-mode)
          if location.name == "Home" do
            g
          else
            g
            |> rect({320, 1}, fill: :red, t: {0, y + 32})
          end
        end)
    end)
  end

  def fetch_open_prs() do
    case Dash.GhStats.fetch() do
      {:ok, rows} ->
        row = hd(rows)
        {row.num_prs_need_review_by_login, row.num_assigned_prs_by_login}

      {:error, _} ->
        {%{}, %{}}
    end
  end

  defp render_weather_component(
         graph,
         location,
         weather_result,
         open_prs_by_author,
         assigned_prs_by_author,
         transform
       ) do
    graph
    |> GraphTools.upsert(location.name, fn g ->
      Dash.WeatherResult.ScenicComponent.upsert(
        g,
        %{
          location: location,
          weather_result: weather_result,
          open_prs_by_author: open_prs_by_author,
          assigned_prs_by_author: assigned_prs_by_author,
        },
        t: transform
      )
    end)
  end

  defp render_background(g, viewport, bg_color) do
    {width, height} = viewport.size

    rect(g, {width, height}, fill: bg_color)
  end

  defp render_time_text(g) do
    now =
      DateTime.now!(Dash.timezone())
      # The display takes about 30 seconds to fully refresh so adjust the rendered time to match
      |> DateTime.add(30, :second)

    time_str = Calendar.strftime(now, "%m/%d %H:%M")

    g
    |> GraphTools.upsert(:time, fn g ->
      text(g, time_str, id: :time, font: :unifont, font_size: 32, t: {610, 470}, fill: :black)
    end)
  end

  def get_quote_author(text) do
    case String.split(text, "–") do
      [quote, author] ->
        {String.trim(quote), String.trim(author)}

      _ ->
        case String.split(text, "-") do
          [quote, author] ->
            {String.trim(quote), String.trim(author)}

          _ ->
            {text, nil}
        end
    end
  end

  defp render_quote_text(g, text) do
    pos = {550, 25}

    {quote, author} = get_quote_author(text)
    {display_text, font, font_size, font_metrics} = wrap_and_shorten_quote(quote)

    g
    |> GraphTools.upsert(:quote_text, fn g ->
      text(g, display_text,
        id: :quote_text,
        font: font,
        font_size: font_size,
        fill: :black,
        t: pos,
        text_align: :center,
        text_base: :top
      )

      g
      |> group(
        fn g ->
          lines = String.split(display_text, "\n")

          lines
          |> Enum.with_index()
          |> Enum.reduce(g, fn {line, idx}, g ->
            y = idx * font_size

            g
            |> text(line,
              # id: :quote_text,
              font: font,
              font_size: font_size,
              fill: :black,
              t: {0, y},
              text_align: :center,
              text_base: :top
            )
          end)
        end,
        id: :quote_text,
        translate: pos
      )
    end)
    |> GraphTools.upsert(:quote_author, fn g ->
      quote_width =
        FontMetrics.width(display_text, font_size, font_metrics)
        |> round()

      lines = String.split(display_text, "\n") |> length()

      {x, y} = pos
      # Magic number that looks good
      y_fudge = 6
      # Use floor to always have an integer value
      y_offset = floor(FontMetrics.points_to_pixels(font_size)) * lines - y_fudge
      author_pos = {x + div(quote_width, 2), y + y_offset}

      author =
        if author do
          "– #{author}"
        else
          ""
        end

      text(g, author,
        id: :quote_author,
        font: font,
        font_size: font_size,
        fill: :black,
        t: author_pos,
        text_align: :right,
        text_base: :top
      )
    end)
  end

  defp render_commitment_text(graph, %Dash.Commitments.Commitment{} = commitment) do
    {x, y} = pos = {350, 158}
    description_pos = {x, y + 24}

    {commitment_description, font, font_size, font_metrics} =
      wrap_and_shorten_commitment(commitment.description)

    title_width = FontMetrics.width(commitment.title, font_size, font_metrics)

    graph
    |> GraphTools.upsert(:commitment_title, fn g ->
      text(g, commitment.title,
        id: :commitment_title,
        font: font,
        font_size: font_size,
        fill: :black,
        t: pos,
        text_align: :left,
        text_base: :top
      )
    end)
    |> GraphTools.upsert(:commitment_separator, fn g ->
      # Underline the text
      # NOTE: Lines don't show up well on my e-ink screen so use a rect
      rect(g, {title_width, 1}, id: :commitment_separator, fill: :black, t: {x, y + 14})
    end)
    |> GraphTools.upsert(:commitment_description, fn g ->
      text(g, commitment_description,
        id: :commitment_description,
        font: font,
        font_size: font_size,
        fill: :black,
        t: description_pos,
        text_align: :left,
        text_base: :top
      )

      g
      |> group(
        fn g ->
          lines = String.split(commitment_description, "\n")

          lines
          |> Enum.with_index()
          |> Enum.reduce(g, fn {line, idx}, g ->
            y = idx * font_size

            g
            |> text(line,
              # id: :quote_text,
              font: font,
              font_size: font_size,
              fill: :black,
              t: {0, y},
              text_align: :left,
              text_base: :top
            )
          end)
        end,
        id: :commitment_description,
        translate: description_pos
      )
    end)
  end

  def render_calendar(graph) do
    today =
      DateTime.now!(Dash.timezone())
      |> DateTime.to_date()

    GraphTools.upsert(graph, :calendar, fn g ->
      Dash.CalendarComponent.upsert(
        g,
        %{
          today: today,
        },
        id: :calendar,
        t: {616, 350}
      )
    end)
  end

  def render_pomodoro(graph) do
    Logger.info("Render PomodoroBarVizComponent")

    GraphTools.upsert(graph, :pomodoro_viz, fn g ->
      Dash.PomodoroBarVizComponent.upsert(
        g,
        Dash.PomodoroBarVizComponent.fetch_params(),
        id: :pomodoro_viz,
        t: {16, 460}
      )
    end)
  end

  defp wrap_and_shorten_quote(text, try \\ 1) do
    line_width =
      case try do
        1 -> 300
        2 -> 400
        3 -> 400
      end

    num_lines =
      case try do
        1 -> 3
        2 -> 3
        3 -> 4
      end

    font_size = 16
    font = :unifont
    {:ok, {_type, font_metrics}} = Scenic.Assets.Static.meta(font)

    display_text =
      ScenicWidgets.Utils.wrap_and_shorten_text(
        text,
        line_width,
        num_lines,
        font_size,
        font_metrics
      )

    # A bit hacky
    cond do
      try == 1 && String.ends_with?(display_text, "…") ->
        wrap_and_shorten_quote(text, 2)

      try == 2 && String.ends_with?(display_text, "…") ->
        wrap_and_shorten_quote(text, 3)

      true ->
        {display_text, font, font_size, font_metrics}
    end
  end

  defp wrap_and_shorten_commitment(text, try \\ 1) do
    line_width =
      case try do
        1 -> 300
        2 -> 400
        3 -> 400
      end

    num_lines =
      case try do
        1 -> 3
        2 -> 3
        3 -> 4
      end

    font_size = 16
    font = :unifont
    {:ok, {_type, font_metrics}} = Scenic.Assets.Static.meta(font)

    display_text =
      ScenicWidgets.Utils.wrap_and_shorten_text(
        text,
        line_width,
        num_lines,
        font_size,
        font_metrics
      )

    # A bit hacky
    cond do
      try == 1 && String.ends_with?(display_text, "…") ->
        wrap_and_shorten_commitment(text, 2)

      try == 2 && String.ends_with?(display_text, "…") ->
        wrap_and_shorten_commitment(text, 3)

      true ->
        {display_text, font, font_size, font_metrics}
    end
  end
end
