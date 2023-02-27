defmodule Dash do
  require Logger

  @pub_sub :dash_pub_sub
  @topic "dash_topic"
  @task_supervisor :dash_task_supervisor

  def pub_sub, do: @pub_sub
  def topic, do: @topic
  def task_sup, do: @task_supervisor

  @doc """
  Sets centered text
  """
  def set_quote(text, bg_color) when is_binary(text) do
    Phoenix.PubSub.broadcast(pub_sub(), topic(), {:set_quote, text, bg_color})
  end

  def update_stats do
    send(Dash.Scene.Home, :update_stats)
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

  def demo do
    api_key = Dash.Env.pirate_weather_api_key()
    honolulu = "21.306944,-157.858333"
    res = Req.get!("https://api.pirateweather.net/forecast/#{api_key}/#{honolulu}?exclude=alerts,minutely,hourly,daily")
    Dash.Weather.parse_result(res.body)
  end

  def demo_web_color_parse do
    color = "rgba(0, 200, 50, 0.2)"

    Dash.WebColorParser.raw_parse(color)
    |> IO.inspect(label: "web_color_parse (dash.ex:107)")
  end

  def demo_path_parse do
    # path =
    #   "M0 11.6 L 1 9.6 L 2 7.600000000000001 L 3 2.3999999999999986 L 4 12.8 L 5 2.0 L 6 10.0 L 7 9.200000000000001 L 8 1.6000000000000014 L 9 1.6000000000000014 L 10 11.2 L 11 17.6 L 12 4.800000000000001 L 13 13.600000000000001 L 14 3.200000000000001 L 15 4.0 L 16 1.1999999999999993V 18 L 0 18 Z"

    path = "M 10,10 11.1,12.5
           L 90,90
           V 10
           H 50"

    Dash.SvgPathParser.parse(path)
    |> IO.inspect(
      label: "test (parser_test.ex:54)",
      limit: :infinity,
      charlists: false,
      pretty: true
    )
  end
end
