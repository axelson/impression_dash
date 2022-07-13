defmodule Dash.Quote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quotes" do
    field :text, :string
    field :url, :string
    field :card_id, :string

    timestamps()
  end

  def changeset(quote, attrs) do
    quote
    |> cast(attrs, [:text, :url, :card_id])
    |> validate_required([:text, :url, :card_id])
    |> unique_constraint([:card_id])
  end
end
