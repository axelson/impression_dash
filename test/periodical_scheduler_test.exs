defmodule PeriodicalSchedulerTest do
  use ExUnit.Case

  test "Ticks correctly" do
    assert PeriodicalScheduler.seconds_till_next_tick(~T[00:26:44.925310]) == 196
    assert PeriodicalScheduler.seconds_till_next_tick(~T[00:14:44]) == 16
    assert PeriodicalScheduler.seconds_till_next_tick(~T[00:00:00]) == 900
    assert PeriodicalScheduler.seconds_till_next_tick(~T[00:05:50]) == 550
  end
end
