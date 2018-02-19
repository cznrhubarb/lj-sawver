defmodule Sawver.Repo.Migrations.CreateTerrain do
  use Ecto.Migration

  def change do
    create table(:terrain, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :xCoord, :integer
      add :yCoord, :integer
      add :object, :text

      timestamps
    end
  end
end
