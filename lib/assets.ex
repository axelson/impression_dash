defmodule Dash.Assets do
  @alias [
    adventures: {:dash, "fonts/adventures.ttf"},
    half: {:dash, "fonts/half_bold_pixel7.ttf"},
    minecraft: {:dash, "fonts/minecraft.ttf"},
    pix_bold: {:dash, "fonts/pix_bold.ttf"},
    pix_sans: {:dash, "fonts/pix_sans.ttf"},
    pixels: {:dash, "fonts/pixels.ttf"},
    quin: {:dash, "fonts/quin.ttf"},
    silk_regular: {:dash, "fonts/silk_regular.ttf"},
    unifont: {:dash, "fonts/unifont.ttf"},
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
