defmodule Dash.Sparkline do
  @moduledoc """
  Receives a `%Contex.Sparkline{}` and converts it to a `%Dash.Sparkline{}`
  """

  use TypedStruct
  alias Contex.ContinuousLinearScale
  alias Contex.Scale

  typedstruct do
    field :closed_path, any(), enforce: true
    field :open_path, any(), enforce: true
    field :fill_color, String.t(), enforce: true
    field :line_color, String.t(), enforce: true
    field :length, pos_integer(), enforce: true
    field :width, pos_integer(), enforce: true
    field :height, pos_integer(), enforce: true
    field :line_width, integer(), enforce: true
  end

  def parse(%Contex.Sparkline{} = sparkline) do
    scale =
      ContinuousLinearScale.new()
      |> ContinuousLinearScale.domain(sparkline.data)
      |> Scale.set_range(sparkline.height, 0)

    x_scale =
      Contex.ContinuousLinearScale.new()
      |> Contex.ContinuousLinearScale.interval_count(sparkline.length - 1)
      |> Contex.ContinuousLinearScale.domain(0, sparkline.length - 1)
      |> Contex.Scale.set_range(0, sparkline.width)

    x_transform = Scale.domain_to_range_fn(x_scale)

    sparkline = %{sparkline | y_transform: Scale.domain_to_range_fn(scale)}

    %__MODULE__{
      closed_path:
        get_closed_path(sparkline, sparkline.height, x_transform)
        |> to_string()
        |> svg_path_to_scenic_path(),
      open_path:
        get_path(sparkline, x_transform)
        |> to_string()
        |> svg_path_to_scenic_path(),
      line_color: sparkline.line_colour,
      fill_color: sparkline.fill_colour,
      length: length(sparkline.data),
      width: sparkline.width,
      height: sparkline.height,
      line_width: sparkline.line_width,
    }
  end

  # These functions are pretty much straight from Contex but I've added an
  # x_transform because scaling the x attribute via Scenic results in too much
  # distortion (the stroke becomes super heavy)
  defp get_closed_path(%Contex.Sparkline{} = sparkline, vb_height, x_transform) do
    # Same as the open path, except we drop down, run back to height,height (aka 0,0) and close it...
    open_path = get_path(sparkline, x_transform)
    [open_path, "V #{vb_height} L 0 #{vb_height} Z"]
  end

  defp get_path(%Contex.Sparkline{y_transform: transform_func} = sparkline, x_transform) do
    last_item = Enum.count(sparkline.data) - 1

    [
      "M",
      sparkline.data
      |> Enum.map(transform_func)
      |> Enum.with_index()
      |> Enum.map(fn {value, i} ->
        x = x_transform.(i)

        case i < last_item do
          true -> "#{x} #{value} L "
          _ -> "#{x} #{value}"
        end
      end),
    ]
  end

  defp svg_path_to_scenic_path(path) do
    {:ok, scenic_path} = Dash.SvgPathParser.parse(path)
    scenic_path
  end
end
