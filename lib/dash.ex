defmodule Dash do
  @pub_sub :dash_pub_sub
  @topic "dash_topic"

  def pub_sub, do: @pub_sub
  def topic, do: @topic

  @doc """
  Sets centered text
  """
  def set_quote(text) when is_binary(text) do
    Phoenix.PubSub.broadcast(pub_sub(), topic(), {:set_quote, text})
  end

  def roboto_font_metrics do
    {:ok, {_type, font_metrics}} = Scenic.Assets.Static.meta(:roboto)
    font_metrics
  end
end
