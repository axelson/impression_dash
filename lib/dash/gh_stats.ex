defmodule Dash.GhStats do
  use TypedStruct
  require Logger

  typedstruct module: Row do
    field :num_prs_needs_review, :integer
    field :num_prs_approved_not_merged, :integer
    field :num_prs_open, :integer
    field :num_outstanding_review_requests, :integer
    field :num_prs_need_review_by_login, :map
    field :num_assigned_prs_by_login, :map
    field :inserted_at, :naive_datetime
  end

  def run do
    Req.new(base_url: gh_stats_base_url())
    |> Req.request(url: "/api/stats.csv")
    |> case do
      {:ok, response} ->
        parse(response.body)
    end
  end

  def fetch do
    if Dash.glamour_shot?() do
      Path.join([:code.priv_dir(:dash), "sample_gh_stats.csv"])
      |> File.read!()
      |> parse()
    else
      Req.new(base_url: gh_stats_base_url())
      |> Req.request(url: "/api/stats.csv")
      |> case do
        {:ok, response} ->
          parse(response.body)

        res ->
          {:error, res}
      end
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
          "num_prs_need_review_by_login",
          "num_assigned_prs_by_login",
          "inserted_at",
        ]
        | rest,
      ] ->
        # This makes me really want to create a nice CSV parser...
        Enum.map(rest, fn raw_row ->
          %Row{
            num_prs_needs_review: String.to_integer(Enum.at(raw_row, 0)),
            num_prs_approved_not_merged: String.to_integer(Enum.at(raw_row, 1)),
            num_prs_open: String.to_integer(Enum.at(raw_row, 2)),
            num_outstanding_review_requests: String.to_integer(Enum.at(raw_row, 3)),
            num_prs_need_review_by_login: Jason.decode!(Enum.at(raw_row, 4)),
            num_assigned_prs_by_login: Jason.decode!(Enum.at(raw_row, 5)),
            inserted_at: NaiveDateTime.from_iso8601!(Enum.at(raw_row, 6)),
          }
        end)
        |> then(&{:ok, &1})

      res ->
        Logger.warning("Unable to parse as stats #{inspect(res)}")
        {:error, {:unable_to_parse, res}}
    end
  end

  defp gh_stats_base_url, do: Application.fetch_env!(:dash, :gh_stats_base_url)
end
