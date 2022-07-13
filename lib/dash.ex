defmodule Dash do
  @pub_sub :dash_pub_sub
  @topic "dash_topic"

  def pub_sub, do: @pub_sub
  def topic, do: @topic

  @doc """
  Sets centered text
  """
  def set_quote(text, bg_color) when is_binary(text) do
    Phoenix.PubSub.broadcast(pub_sub(), topic(), {:set_quote, text, bg_color})
  end

  def switch_scene(scene_id) do
    {:ok, view_port} = Scenic.ViewPort.info(:main_viewport)
    {scene, params} = scene_definition(scene_id)
    Scenic.ViewPort.set_root(view_port, scene, params)
  end

  defp scene_definition(:home), do: {Dash.Scene.Home, []}
  defp scene_definition(:color_test), do: {Dash.Scene.ColorTest, []}

  def roboto_font_metrics do
    {:ok, {_type, font_metrics}} = Scenic.Assets.Static.meta(:roboto)
    font_metrics
  end
end
