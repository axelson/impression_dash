defmodule Dash.Repo.Migrations.Quotes do
  use Ecto.Migration

  def change do
    create table("quotes") do
      add :text, :text
      add :url, :text
      add :card_id, :text

      timestamps()
    end

    create unique_index(:quotes, [:card_id])
  end
end
