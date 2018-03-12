defmodule Sawver.Repo.Migrations.AddProdRateToBlueprint do
  use Ecto.Migration

  def change do
    alter table(:blueprints) do
      add :production_rate, :float
    end
  end
end
