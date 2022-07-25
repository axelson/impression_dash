defmodule Dash.Sparkline.ScenicComponent do
  @moduledoc """
  Renders a Contex Sparkline as a Scenic Component

  Notes are from: https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d
  """
  use Scenic.Component
  use TypedStruct
  import Scenic.Primitives
  require Logger
  alias Scenic.Graph
  alias ScenicWidgets.GraphState

  @alpha_scale Dash.Scale.new_continuous(domain: {0, 1}, range: {0, 255})

  # @data [50, 74, 100, 103, 82, 55, 75, 73, 54, 54, 78, 94, 62, 84, 58, 60, 53]
  @data [
    -83,
    -78,
    -58,
    -67,
    -74,
    -58,
    -78,
    -86,
    -90,
    -57,
    -68,
    -69,
    -98,
    -85,
    -80,
    -79,
    -98,
    -88
    # -68,
    # -59,
    # -74,
    # -88,
    # -67,
    # -77,
    # -67,
    # -84,
    # -65,
    # -52,
    # -87,
    # -50,
    # -50,
    # -71,
    # -79,
    # -95,
    # -92,
    # -63,
    # -85,
    # -60,
    # -88,
    # -55,
    # -59,
    # -67,
    # -90,
    # -93,
    # -63,
    # -95,
    # -76,
    # -75,
    # -91,
    # -62
  ]

  @sparkline %Contex.Sparkline{
    data: @data,
    extents: {-98, -50},
    fill_colour: "rgba(0, 200, 50, 0.2)",
    width: 300,
    height: 50,
    length: length(@data),
    line_colour: "rgba(0, 200, 50, 0.7)",
    line_width: 1,
    spot_colour: "red",
    spot_radius: 2,
    y_transform: nil
  }

  typedstruct module: State do
    field :graph, Scenic.Graph.t()
  end

  defmodule Path do
    use TypedStruct

    typedstruct do
      field :initial_x, number(), enforce: true
      field :initial_y, number(), enforce: true
      field :x, number(), enforce: true
      field :y, number(), enforce: true
      field :commands, list(), enforce: true
    end

    def add_command(%Path{} = path, command) do
      %Path{path | commands: [command | path.commands]}
    end

    def add_command(%Path{} = path, command, {x, y}) do
      add_command(%Path{path | x: x, y: y}, command)
    end
  end

  def draw, do: draw(@sparkline)

  def draw(%Contex.Sparkline{} = sparkline) do
    Dash.Sparkline.parse(sparkline)
  end

  @impl Scenic.Component
  def validate(params), do: {:ok, params}

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    dash_sparkline = Dash.Sparkline.parse(@sparkline)

    graph =
      Graph.build()
      |> render_sparkline(dash_sparkline, [])

    state = %State{}
    scene = GraphState.assign_and_push_graph(scene, state, graph)

    {:ok, scene}
  end

  def scenic_color(web_color_string) do
    case Dash.WebColorParser.parse(web_color_string) do
      {:ok, {:rgba, {r, g, b, a}}} ->
        alpha = Contex.Scale.domain_to_range(@alpha_scale, a)
        alpha = round(alpha)
        {:color_rgba, {r, g, b, alpha}}

      other ->
        Logger.warn("Error or unrecognized web color #{inspect(other)}")
        :red
    end
  end

  def render_sparkline(graph, dash_sparkline, _opts) do
    scale = 1

    fill_color = scenic_color(dash_sparkline.fill_color)
    line_color = scenic_color(dash_sparkline.line_color)

    graph
    |> path(to_scenic_path(dash_sparkline.open_path, dash_sparkline),
      stroke: {dash_sparkline.line_width, line_color},
      miter_limit: 3,
      join: :round,
      scale: scale,
      scissor: {dash_sparkline.width, dash_sparkline.height}
    )
    |> path(to_scenic_path(dash_sparkline.closed_path, dash_sparkline),
      fill: fill_color,
      scale: scale
    )
  end

  _sample = [
    abs_move_to: [[0, 11.6]],
    abs_line_to: [[1, 9.6]],
    abs_line_to: [[2, 7.600000000000001]],
    abs_line_to: [[3, 2.3999999999999986]],
    abs_line_to: [[4, 12.8]],
    abs_line_to: [[5, 2.0]],
    abs_line_to: [[6, 10.0]],
    abs_line_to: [[7, 9.200000000000001]],
    abs_line_to: [[8, 1.6000000000000014]],
    abs_line_to: [[9, 1.6000000000000014]],
    abs_line_to: [[10, 11.2]],
    abs_line_to: [[11, 17.6]],
    abs_line_to: [[12, 4.800000000000001]],
    abs_line_to: [[13, 13.600000000000001]],
    abs_line_to: [[14, 3.200000000000001]],
    abs_line_to: [[15, 4.0]],
    abs_line_to: [[16, 1.1999999999999993]]
  ]

  def to_scenic_path(commands, _dash_sparkline) do
    # IO.inspect(commands, label: "commands (scenic_component.ex:126)")
    path = %Path{x: 0, y: 0, initial_x: 0, initial_y: 0, commands: []}
    path = Path.add_command(path, {:move_to, 0, 0})

    path =
      commands
      |> Enum.reduce(path, fn command, path ->
        update_path(path, command)
      end)

    Enum.reverse(path.commands)
    # |> IO.inspect(label: "path commands (scenic_component.ex:137)")
  end

  def update_path(path, draw_command)

  # Move the current point to the coordinate x,y. Any subsequent coordinate
  # pair(s) are interpreted as parameter(s) for implicit absolute LineTo (L)
  # command(s).
  def update_path(%Path{} = path, {:abs_move_to, [{x, y} | coordinate_pairs]}) do
    # First coordinate pair of :abs_move_to represents a :move_to, rest represent line_to
    path = Path.add_command(path, {:move_to, x, y}, {x, y})
    path = %Path{path | initial_x: x, initial_y: y}

    update_path(path, {:abs_line_to, coordinate_pairs})
  end

  # Move the current point by shifting the last known position of the path by dx
  # along the x-axis and by dy along the y-axis. Any subsequent coordinate
  # pair(s) are interpreted as parameter(s) for implicit relative LineTo (l)
  # command(s).
  def update_path(%Path{} = path, {:rel_move_to, [{x, y} | coordinate_pairs]}) do
    # First coordinate pair of :rel_move_to represents a :move_to, rest represent line_to
    {new_x, new_y} = {path.x + x, path.y + y}
    path = Path.add_command(path, {:move_to, new_x, new_y}, {new_x, new_y})
    path = %Path{path | initial_x: new_x, initial_y: new_y}

    update_path(path, {:rel_line_to, coordinate_pairs})
  end

  # Draw a line from the current point to the end point specified by x,y. Any
  # subsequent coordinate pair(s) are interpreted as parameter(s) for implicit
  # absolute LineTo (L) command(s).
  def update_path(%Path{} = path, {:abs_line_to, coordinate_pairs}) do
    coordinate_pairs
    |> Enum.reduce(path, fn {x, y}, path ->
      Path.add_command(path, {:line_to, x, y}, {x, y})
    end)
  end

  # Draw a line from the current point to the end point, which is the current
  # point shifted by dx along the x-axis and dy along the y-axis. Any subsequent
  # coordinate pair(s) are interpreted as parameter(s) for implicit relative
  # LineTo (l) command(s).
  def update_path(%Path{} = path, {:rel_line_to, coordinate_pairs}) do
    coordinate_pairs
    |> Enum.reduce(path, fn {x, y}, path ->
      {new_x, new_y} = {path.x + x, path.y + y}
      Path.add_command(path, {:line_to, new_x, new_y}, {new_x, new_y})
    end)
  end

  # Draw a vertical line from the current point to the end point, which is
  # specified by the y parameter and the current point's x coordinate. Any
  # subsequent values are interpreted as parameters for implicit absolute
  # vertical LineTo (V) command(s).
  def update_path(%Path{} = path, {:abs_vertical_line_to, y_coordinates}) do
    y_coordinates
    |> Enum.reduce(path, fn y, path ->
      Path.add_command(path, {:line_to, path.x, y}, {path.x, y})
    end)
  end

  # Draw a vertical line from the current point to the end point, which is
  # specified by the current point shifted by dy along the y-axis and the
  # current point's x coordinate. Any subsequent value(s) are interpreted as
  # parameter(s) for implicit relative vertical LineTo (v) command(s).
  def update_path(%Path{} = path, {:rel_vertical_line_to, y_coordinates}) do
    y_coordinates
    |> Enum.reduce(path, fn y, path ->
      new_y = path.y + y
      Path.add_command(path, {:line_to, path.x, new_y}, {path.x, new_y})
    end)
  end

  # Draw a horizontal line from the current point to the end point, which is
  # specified by the x parameter and the current point's y coordinate. Any
  # subsequent value(s) are interpreted as parameter(s) for implicit absolute
  # horizontal LineTo (H) command(s).
  def update_path(%Path{} = path, {:abs_horizontal_line_to, x_coordinates}) do
    x_coordinates
    |> Enum.reduce(path, fn x, path ->
      Path.add_command(path, {:line_to, x, path.y}, {x, path.y})
    end)
  end

  # Draw a horizontal line from the current point to the end point, which is
  # specified by the current point shifted by dx along the x-axis and the
  # current point's y coordinate. Any subsequent value(s) are interpreted as
  # parameter(s) for implicit relative horizontal LineTo (h) command(s).
  def update_path(%Path{} = path, {:rel_horizontal_line_to, x_coordinates}) do
    x_coordinates
    |> Enum.reduce(path, fn x, path ->
      new_x = path.x + x
      Path.add_command(path, {:line_to, new_x, path.x}, {new_x, path.x})
    end)
  end

  # Close the current subpath by connecting the last point of the path with its
  # initial point. If the two points are at different coordinates, a straight
  # line is drawn between those two points.
  def update_path(%Path{} = path, :close_path) do
    Path.add_command(path, :close_path, {path.initial_x, path.initial_y})
  end

  def update_path(%Path{} = path, command) do
    Logger.warn("Unrecognized command #{inspect(command)}")
    path
  end
end
