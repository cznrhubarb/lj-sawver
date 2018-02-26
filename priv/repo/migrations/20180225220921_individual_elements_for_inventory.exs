defmodule Sawver.Repo.Migrations.IndividualElementsForInventory do
  use Ecto.Migration

  def change do
    alter table(:inventories) do
      remove :items

      add :wood, :integer
      add :stone, :integer
      add :rope, :integer
      add :cloth, :integer
      add :gold, :integer

      add :steel, :integer
      add :paper, :integer
      add :water, :integer
      add :gems, :integer
      add :magic, :integer
    end
  end
end
