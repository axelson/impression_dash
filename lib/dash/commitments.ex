defmodule Dash.Commitments do
  alias Dash.Commitments.Commitment

  @path Path.join([:code.priv_dir(:dash), "the_15_commitments_of_conscious_leaders.json"])
  @external_resource @path

  @json Jason.decode!(File.read!(@path))
  @commitments Enum.map(
                 @json["commitments"],
                 &%Commitment{title: &1["title"], description: &1["description"]}
               )

  def commitments, do: @commitments

  def random_commitment do
    if Dash.glamour_shot?() do
      Enum.at(commitments(), 1)
    else
      Enum.random(commitments())
    end
  end
end
