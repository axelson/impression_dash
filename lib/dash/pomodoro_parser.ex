defmodule Dash.PomodoroParser do
  def parse(csv) when is_binary(csv) do
    today = DateTime.now!("Pacific/Honolulu") |> DateTime.to_date()

    NimbleCSV.RFC4180.parse_string(csv)
    |> Enum.map(fn row ->
      [started_at, finished_at, rest_started_at, rest_finished_at, total_seconds] = row

      %{
        started_at: to_hawaii_time(started_at),
        finished_at: to_hawaii_time(finished_at),
        rest_started_at: to_hawaii_time(rest_started_at),
        rest_finished_at: to_hawaii_time(rest_finished_at),
        total_seconds: total_seconds,
      }
    end)
    |> Enum.filter(fn row ->
      DateTime.to_date(row.started_at) == today
    end)
  end

  def to_hawaii_time(""), do: nil

  def to_hawaii_time(time_str) do
    time_str
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Pacific/Honolulu")
  end

  def sample_csv do
    path = Path.join([:code.priv_dir(:dash), "sample_pomodoro_stats.csv"])
    File.read!(path)
  end
end
