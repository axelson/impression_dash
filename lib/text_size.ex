defmodule Dash.TextSize do
  # use Scenic.Scene
  # use Scenic.Component
  use Scenic.Component, has_children: false
  # use ScenicWidgets.GraphTools.Upsertable

  import Scenic.Primitives

  alias Scenic.Graph

  @font Dash.font()

  @impl Scenic.Component
  def validate(params), do: {:ok, params}

  @impl Scenic.Scene
  def init(scene, _params, _opts) do
    graph = Graph.build(font: @font)
    # gautami?

    # https://www.fontspace.com/category/pixel?p=4
    # fonts/quin.ttf
    # 5px or 10px
    #
    # fonts/minecraft.ttf
    # 10px or 20px
    #
    # fonts/silk_regular.ttf
    # 8px or 16px
    #
    # fonts/pix_sans.ttf
    # 9px or 18px
    #
    # fonts/pix_bold.ttf - kinda ugly
    # 9px or 18px
    #
    # fonts/pixels.ttf
    # 16px (but it's TINY)
    #
    # fonts/unifont.ttf - looks great!
    # 16px
    #
    # fonts/adventures.ttf
    # 7px or 14px or 21px
    #
    # fonts/half_bold_pixel7.ttf
    # 10px, 20px
    #
    # fonts/connection.ttf - kinda ugly
    # 20px
    #
    # fonts/roboto_remix.ttf - soso
    # 16px
    #
    # fonts/lcd.ttf
    # 19px (but I don't like how it looks)

    # for {font, x} <- [{:terminus, 250}, {:roboto, 450}], size <- 8..20 do
    #   {font, x, size}
    # end
    fonts =
      for {font, x} <- [
            {"fonts/connection3.ttf", 5},
            {"fonts/roboto_remix.ttf", 420},
          ],
          size <- 6..26 do
        {font, x, size}
      end
      |> Enum.with_index()

    graph =
      Enum.reduce(fonts, graph, fn {{font, x, font_size}, _i}, g ->
        text(g, inspect({font, font_size}),
          fill: :black,
          font: font,
          font_size: font_size,
          translate: {x, font_size * font_size - font_size * 9 + 30}
        )
      end)

    scene =
      scene
      |> Scenic.Scene.assign(
        id: :some_id,
        graph: graph
      )
      |> Scenic.Scene.push_graph(graph)

    {:ok, scene}
  end
end
