defmodule Dash.Scale do
  @moduledoc """
  First stab at a nicer interface to Contex's scales

  But with a hacky attempt to remove the tick rounding
  """

  def new_continuous(opts \\ []) do
    {min_domain, max_domain} = Keyword.fetch!(opts, :domain)
    {min_range, max_range} = Keyword.fetch!(opts, :range)

    Contex.ContinuousLinearScale.new()
    |> Contex.ContinuousLinearScale.interval_count(max_domain)
    |> Contex.ContinuousLinearScale.domain(min_domain, max_domain)
    |> Contex.Scale.set_range(min_range, max_range)
  end
end
