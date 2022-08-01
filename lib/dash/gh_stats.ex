defmodule Dash.GhStats do
  use TypedStruct

  typedstruct module: Row do
    field :num_prs_needs_review, :integer
    field :num_prs_approved_not_merged, :integer
    field :num_prs_open, :integer
    field :num_outstanding_review_requests, :integer
    field :inserted_at, :naive_datetime
  end

  def run do
    Req.new(base_url: "http://192.168.1.2:4004")
    |> Req.request(url: "/api/stats.csv")
    |> case do
      {:ok, response} ->
        parse(response.body)
    end
  end

  def parse(csv) do
    case NimbleCSV.RFC4180.parse_string(csv, skip_headers: false) do
      [
        [
          "num_prs_needs_review",
          "num_prs_approved_not_merged",
          "num_prs_open",
          "num_outstanding_review_requests",
          "inserted_at"
        ]
        | rest
      ] ->
        # This makes me really want to create a nice CSV parser...
        Enum.map(rest, fn raw_row ->
          %Row{
            num_prs_needs_review: String.to_integer(Enum.at(raw_row, 0)),
            num_prs_approved_not_merged: String.to_integer(Enum.at(raw_row, 1)),
            num_prs_open: String.to_integer(Enum.at(raw_row, 2)),
            num_outstanding_review_requests: String.to_integer(Enum.at(raw_row, 3)),
            inserted_at: NaiveDateTime.from_iso8601!(Enum.at(raw_row, 4))
          }
        end)
    end
  end
end
