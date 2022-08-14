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
  alias ScenicWidgets.GraphTools

  @alpha_scale Dash.Scale.new_continuous(domain: {0, 1}, range: {0, 255})

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

  @impl Scenic.Component
  def validate(params), do: {:ok, params}

  @impl Scenic.Scene
  def init(scene, params, _opts) do
    graph = Graph.build()

    state = %State{}

    scene = GraphState.assign_and_push_graph(scene, state, graph)

    # Draw the sparkline only if we have it
    scene =
      case params do
        %{dash_sparkline: dash_sparkline} ->
          GraphState.update_graph(scene, fn graph ->
            graph
            |> GraphTools.upsert(:sparkline, fn g -> render_sparkline(g, dash_sparkline, []) end)
          end)

        _ ->
          scene
      end

    {:ok, scene}
  end

  def upsert(graph_or_primitive, data, opts) do
    case graph_or_primitive do
      %Scenic.Graph{} = graph -> add_to_graph(graph, data, opts)
      %Scenic.Primitive{} = primitive -> modify(primitive, data, opts)
    end
  end

  # Copied from Scenic:
  # https://github.com/boydm/scenic/blob/94679b1ab50834e20b94ca11bc0c5645bf0c909e/lib/scenic/components.ex#L696
  defp modify(
         %Scenic.Primitive{module: Scenic.Primitive.Component, data: {mod, _, id}} = p,
         data,
         options
       ) do
    data =
      case mod.validate(data) do
        {:ok, data} -> data
        {:error, msg} -> raise msg
      end

    Scenic.Primitive.put(p, {mod, data, id}, options)
  end

  # Copied from Scenic:
  # https://github.com/boydm/scenic/blob/9314020b2962e38bea871e8e1f59cd273dfe0af0/lib/scenic/primitives.ex#L1467
  defp modify(%Scenic.Primitive{module: mod} = p, data, opts) do
    data =
      case mod.validate(data) do
        {:ok, data} -> data
        {:error, error} -> raise Exception.message(error)
      end

    Scenic.Primitive.put(p, data, opts)
  end

  @impl Scenic.Scene
  def handle_update(params, _opts, scene) do
    %{dash_sparkline: dash_sparkline} = params

    scene =
      GraphState.update_graph(scene, fn graph ->
        graph
        |> GraphTools.upsert(:sparkline, fn g -> render_sparkline(g, dash_sparkline, []) end)
      end)

    {:noreply, scene}
  end

  @impl GenServer
  def handle_info(msg, scene) do
    Logger.warn("Unhandled message: #{inspect(msg)}")
    {:noreply, scene}
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
    |> group(
      fn g ->
        g
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
      end,
      id: :sparkline
    )
  end

  def to_scenic_path(commands, _dash_sparkline) do
    path = %Path{x: 0, y: 0, initial_x: 0, initial_y: 0, commands: []}
    path = Path.add_command(path, {:move_to, 0, 0})

    path =
      commands
      |> Enum.reduce(path, fn command, path ->
        update_path(path, command)
      end)

    Enum.reverse(path.commands)
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
