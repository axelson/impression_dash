defmodule Dash.PomodoroParser do
  def parse(csv, opts \\ []) when is_binary(csv) do
    filter = Keyword.get(opts, :filter?, true)
    today = Keyword.get(opts, :today, DateTime.now!(Dash.timezone()) |> DateTime.to_date())

    NimbleCSV.RFC4180.parse_string(csv)
    |> Enum.map(fn row ->
      [started_at, finished_at, rest_started_at, rest_finished_at, total_seconds] = row

      %{
        started_at: to_local_time(started_at),
        finished_at: to_local_time(finished_at),
        rest_started_at: to_local_time(rest_started_at),
        rest_finished_at: to_local_time(rest_finished_at),
        total_seconds: String.to_integer(total_seconds),
      }
    end)
    |> Enum.filter(fn row ->
      if filter do
        DateTime.to_date(row.started_at) == today
      else
        true
      end
    end)
  end

  def to_local_time(""), do: nil

  def to_local_time(time_str) do
    time_str
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(Dash.timezone())
  end

  def sample_csv do
    path = Path.join([:code.priv_dir(:dash), "sample_pomodoro_stats.csv"])
    File.read!(path)
  end
end
