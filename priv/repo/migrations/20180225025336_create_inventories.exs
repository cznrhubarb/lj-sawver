defmodule Sawver.Repo.Migrations.CreateInventories do
  use Ecto.Migration

  def change do
    create table(:inventories, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :items, :map

      timestamps()
    end

  end
end
