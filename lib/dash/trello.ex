defmodule Dash.Trello do
  @base_url "https://api.trello.com"

  def fetch_lists(board_id \\ Dash.TrelloInfo.board_id()) do
    Req.new(base_url: @base_url)
    |> Req.request(
      url: "/1/boards/#{board_id}/lists",
      params: [key: trello_key(), token: trello_token()]
    )
  end

  # GET /1/lists/{id}/cards
  def fetch_quotes(list_id \\ Dash.TrelloInfo.quotes_list_id()) do
    Req.new(
      base_url: @base_url,
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

  def save_quotes do
    cards_attrs = fetch_quotes()

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

  def all_quotes do
    Dash.Repo.all(Dash.Quote)
  end

  def random_quote do
    Enum.random(all_quotes())
  end

  def display_quote(%Dash.Quote{} = quote) do
    Phoenix.PubSub.broadcast(Dash.pub_sub(), Dash.topic(), {:set_quote, quote.text})
  end

  def base_req do
    Req.new(
      base_url: "https://api.trello.com",
      params: [key: trello_key(), token: trello_token()]
    )
  end

  defp trello_key, do: Dash.Env.trello_api_key()
  defp trello_token, do: Dash.Env.trello_api_token()
end
