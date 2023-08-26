defmodule Dash.PomodoroSampleData do
  @samples [
    [
      %{
        started_at: %{
          microsecond: {0, 0},
          second: 53,
          calendar: Calendar.ISO,
          month: 8,
          __struct__: DateTime,
          day: 26,
          year: 2023,
          minute: 33,
          hour: 8,
          time_zone: "Pacific/Honolulu",
          zone_abbr: "HST",
          utc_offset: -36000,
          std_offset: 0,
        },
        finished_at: %{
          microsecond: {0, 0},
          second: 53,
          calendar: Calendar.ISO,
          month: 8,
          __struct__: DateTime,
          day: 26,
          year: 2023,
          minute: 33,
          hour: 9,
          time_zone: "Pacific/Honolulu",
          zone_abbr: "HST",
          utc_offset: -36000,
          std_offset: 0,
        },
        rest_finished_at: nil,
        rest_started_at: nil,
        total_seconds: "1800",
      },
    ],
    [
      %{
        started_at: %{
          microsecond: {0, 0},
          second: 53,
          calendar: Calendar.ISO,
          month: 8,
          __struct__: DateTime,
          day: 26,
          year: 2023,
          minute: 33,
          hour: 13,
          time_zone: "Pacific/Honolulu",
          zone_abbr: "HST",
          utc_offset: -36000,
          std_offset: 0,
        },
        finished_at: %{
          microsecond: {0, 0},
          second: 53,
          calendar: Calendar.ISO,
          month: 8,
          __struct__: DateTime,
          day: 26,
          year: 2023,
          minute: 33,
          hour: 14,
          time_zone: "Pacific/Honolulu",
          zone_abbr: "HST",
          utc_offset: -36000,
          std_offset: 0,
        },
        rest_finished_at: nil,
        rest_started_at: nil,
        total_seconds: "1800",
      },
    ],
  ]

  def sample do
    idx = System.unique_integer([:positive, :monotonic])
    Enum.at(@samples, rem(idx, 2))
  end
end
