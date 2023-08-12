defmodule Dash.Assets do
  @alias [
    adventures: "fonts/adventures.ttf",
    half: "fonts/half_bold_pixel7.ttf",
    minecraft: "fonts/minecraft.ttf",
    pix_bold: "fonts/pix_bold.ttf",
    pix_sans: "fonts/pix_sans.ttf",
    pixels: "fonts/pixels.ttf",
    quin: "fonts/quin.ttf",
    silk_regular: "fonts/silk_regular.ttf",
    unifont: "fonts/unifont.ttf",
  ]

  use Scenic.Assets.Static,
    otp_app: :dash,
    alias: @alias,
    sources: [
      "assets",
      {:scenic, "deps/scenic/assets"},
    ]

  def asset_path, do: Path.join([__DIR__, "..", "assets"]) |> Path.expand()

  def alias, do: @alias
end
