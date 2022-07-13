defmodule Dash do
  require Logger

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

  # GET /1/boards/{id}/lists
  def fetch_lists do
    board_id = "5foyI8pX"

    Req.new(base_url: "https://api.trello.com")
    |> Req.request(
      url: "/1/boards/#{board_id}/lists",
      params: [key: trello_key(), token: trello_token()]
    )
  end

  # GET /1/lists/{id}/cards
  def fetch_quotes(list_id \\ Dash.TrelloInfo.list_id()) do
    Req.new(
      base_url: "https://api.trello.com",
      params: [key: trello_key(), token: trello_token()]
    )
    |> Req.request(url: "/1/lists/#{list_id}/cards")
    |> case do
      {:ok, response} ->
        Enum.map(response.body, fn card ->
          %{"text" => card["name"], "card_id" => card["id"], "url" => card["url"]}
        end)
    end
  end

  def fetch_board_cards do
    board_id = "5foyI8pX"

    base_req()
    |> Req.request(url: "/1/boards/#{board_id}/lists")
  end

  def display_random_quote do
    quote = Enum.random(all_quotes())
    Logger.info("Displaying #{quote.text}")

    set_quote(quote.text, :white)
  end

  def all_quotes do
    Dash.Repo.all(Dash.Quote)
  end

  def store_quotes(cards_attrs) do
    Enum.map(cards_attrs, fn attrs ->
      store_quote(attrs)
    end)
  end

  def store_quote(attrs) do
    %Dash.Quote{}
    |> Dash.Quote.changeset(attrs)
    |> Dash.Repo.insert!(
      on_conflict: :replace_all,
      conflict_target: :card_id
    )
  end

  defp base_req do
    Req.new(
      base_url: "https://api.trello.com",
      params: [key: trello_key(), token: trello_token()]
    )
  end

  defp trello_key, do: Application.fetch_env!(:dash, :trello_api_key)
  defp trello_token, do: Application.fetch_env!(:dash, :trello_api_token)
end
