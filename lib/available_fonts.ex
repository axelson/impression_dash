defmodule Dash.AvailableFonts do
  use Scenic.Component, has_children: false
  import Scenic.Primitives
  alias Scenic.Graph

  @impl Scenic.Component
  def validate(params), do: {:ok, params}

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    graph = Graph.build()

    fonts =
      [
        {{:dash, "fonts/unifont.ttf"}, 16, 20},
        {{:dash, "fonts/unifont.ttf"}, 32, 30},
        {{:dash, "fonts/quin.ttf"}, 5, 15},
        {{:dash, "fonts/quin.ttf"}, 10, 20},
        {{:dash, "fonts/minecraft.ttf"}, 10, 15},
        {{:dash, "fonts/minecraft.ttf"}, 20, 25},
        {{:dash, "fonts/silk_regular.ttf"}, 8, 15},
        {{:dash, "fonts/silk_regular.ttf"}, 16, 20},
        {{:dash, "fonts/pix_sans.ttf"}, 9, 15},
        {{:dash, "fonts/pix_sans.ttf"}, 18, 20},
        {{:dash, "fonts/pixels.ttf"}, 16, 15},
        {{:dash, "fonts/pixels.ttf"}, 32, 20},
        {{:dash, "fonts/adventures.ttf"}, 7, 15},
        {{:dash, "fonts/adventures.ttf"}, 14, 20},
        {{:dash, "fonts/adventures.ttf"}, 21, 30},
        {{:dash, "fonts/half_bold_pixel7.ttf"}, 10, 15},
        {{:dash, "fonts/half_bold_pixel7.ttf"}, 20, 25},
        {{:dash, "fonts/pix_bold.ttf"}, 9, 15},
        {{:dash, "fonts/pix_bold.ttf"}, 18, 25},
      ]
      |> Enum.with_index()

    {graph, _y} =
      Enum.reduce(fonts, {graph, 0}, fn {{font, font_size, dy}, _i}, {g, y} ->
        g =
          text(g, inspect({font, font_size}),
            fill: :black,
            font: font,
            font_size: font_size,
            translate: {5, y + dy}
          )

        {g, y + dy}
      end)

    {:ok, push_graph(scene, graph)}
  end
end
