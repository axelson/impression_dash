defmodule Dash.CalendarComponent do
  use Scenic.Component
  import Scenic.Primitives
  alias Scenic.Graph

  @font_size 16

  @impl Scenic.Component
  def validate(params) do
    {:ok, params}
  end

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    today = Date.utc_today()
    day_width = 24

    width = 7 * day_width

    graph =
      Graph.build(font: :unifont, font_size: @font_size, fill: :black)
      |> text(Calendar.strftime(today, "%B"),
        text_align: :center,
        t: {div(width, 2), -2}
      )

    {graph, week} =
      all_days_of_current_month()
      |> Enum.reduce({graph, 0}, fn day, {graph, week} ->
        day_of_week = Date.day_of_week(day, :sunday)

        week =
          if day.day != 1 && day_of_week == 1 do
            week + 1
          else
            week
          end

        {text_x, text_y} = text_pos = {(day_of_week - 1) * day_width + 18, week * @font_size + 16}

        graph =
          if day == today do
            graph
            |> circle(4, fill: :black, t: {-27, week * @font_size + 12})
            |> rect({20, 18}, fill: :black, t: {text_x - 18, text_y - 14})
          else
            graph
          end

        graph =
          graph
          |> text(Calendar.strftime(day, "%-d"),
            t: text_pos,
            fill:
              if day == today do
                :white
              else
                :black
              end,
            text_align: :right
          )

        {graph, week}
      end)

    # Divider between week numbers and calendar dates
    graph =
      graph
      |> rect({1, @font_size * (week + 1) + 2}, t: {-2, 0}, fill: :black)

    # Week numbers
    graph =
      all_days_of_current_month()
      |> Enum.map(fn day -> :calendar.iso_week_number({day.year, day.month, day.day}) end)
      |> Enum.uniq()
      |> Enum.map(fn {_year, week} -> week end)
      |> Enum.with_index()
      |> Enum.reduce(graph, fn {week, idx}, graph ->
        text_pos = {-21, idx * @font_size + 16}

        graph
        |> text(to_string(week),
          t: text_pos
        )
      end)

    graph =
      graph
      |> rect({width + 2, 1}, fill: :black, t: {-2, 0})

    # |> rect({width, @font_size * (week + 1) + 2},
    #   fill: :transparent,
    #   stroke: {1, :black},
    #   t: {0, 1}
    # )

    {:ok, push_graph(scene, graph)}
  end

  def all_days_of_current_month do
    # TODO: Use time zone
    today = Date.utc_today()

    first_day = Date.beginning_of_month(today)

    last_day = Date.end_of_month(today)

    Enum.to_list(Date.range(first_day, last_day))
  end
end
