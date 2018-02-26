defmodule Sawver.Repo.Migrations.InventoryBelongsToLumberjack do
  use Ecto.Migration

  def change do
    alter table(:lumberjacks) do
      remove :inventory_id
    end

    alter table(:inventories) do
      add :lumberjack_id, references(:lumberjacks, type: :uuid)
    end
  end
end
