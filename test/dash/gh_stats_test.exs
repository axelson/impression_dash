defmodule Dash.GhStatsTest do
  use ExUnit.Case
  use Machete

  test "returns error when columns don't match" do
    csv =
      "started_at,finished_at,rest_started_at,rest_finished_at,total_seconds\r\n2024-07-30 11:37:29,2024-07-30 11:38:55.704579,,,1800\r\n"

    assert ExUnit.CaptureLog.capture_log(fn ->
             assert Dash.GhStats.parse(csv) ~> {:error, {:unable_to_parse, term()}}
           end) =~ "Unable to parse"
  end

  test "can parse with correct columns" do
    csv = File.read!(Path.join([__DIR__, "..", "fixtures", "correct.csv"]))

    assert Dash.GhStats.parse(csv)
           ~> {:ok,
            [
              %Dash.GhStats.Row{
                inserted_at: ~N[2024-08-01 12:00:04],
                num_assigned_prs_by_login: %{
                  "ChrisLoer" => 1,
                  "axelson" => 1,
                  "corbinmuraro" => 1,
                  "doorgan" => 1,
                  "kyleVsteger" => 3,
                  "noisyneuron" => 2,
                  "sullvn" => 1,
                  "tomhicks" => 1,
                },
                num_prs_need_review_by_login: %{
                  "Clebal" => 3,
                  "arredond" => 3,
                  "axelson" => 4,
                  "corbinmuraro" => 1,
                  "dependabot" => 7,
                  "dnomadb" => 1,
                  "doorgan" => 2,
                  "e-n-f" => 4,
                  "ibesora" => 1,
                  "kyleVsteger" => 5,
                  "migurski" => 1,
                  "noisyneuron" => 1,
                  "s3cur3" => 1,
                  "samhashemi" => 1,
                  "sullvn" => 1,
                  "tomhicks" => 3,
                },
                num_outstanding_review_requests: 14,
                num_prs_open: 73,
                num_prs_approved_not_merged: 9,
                num_prs_needs_review: 39,
              },
              struct_like(Dash.GhStats.Row, %{}),
              struct_like(Dash.GhStats.Row, %{}),
            ]}
  end
end
