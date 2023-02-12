defmodule Dash.Assets do
  use Scenic.Assets.Static,
    otp_app: :dash,
    sources: [
      "assets",
      {:scenic, "deps/scenic/assets"}
    ]

  def asset_path, do: Path.join([__DIR__, "..", "..", "assets"]) |> Path.expand()
end
