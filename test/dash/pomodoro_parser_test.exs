defmodule Dash.PomodoroParserTest do
  use ExUnit.Case
  use Machete
  use Mneme

  @case1 """
  started_at,finished_at,rest_started_at,rest_finished_at,total_seconds
  2023-11-04 19:03:06,2023-11-04 19:09:12,,,1800
  2023-11-04 19:10:13,2023-11-04 19:26:16.953404,,,1800
  """
  test "parses case1" do
    today = ~D[2023-11-04]

    expected = [
      %{
        started_at: datetime(roughly: ~U[2023-11-04 19:03:12Z], time_zone: "Pacific/Honolulu"),
        finished_at: datetime(roughly: ~U[2023-11-04 19:09:12Z], time_zone: "Pacific/Honolulu"),
        rest_started_at: nil,
        rest_finished_at: nil,
        total_seconds: 1800,
      },
      %{
        started_at: datetime(roughly: ~U[2023-11-04 19:10:13Z], time_zone: "Pacific/Honolulu"),
        finished_at: datetime(roughly: ~U[2023-11-04 19:26:16Z], time_zone: "Pacific/Honolulu"),
        rest_started_at: nil,
        rest_finished_at: nil,
        total_seconds: 1800,
      },
    ]

    assert Dash.PomodoroParser.parse(@case1, today: today) ~> expected
  end
end
