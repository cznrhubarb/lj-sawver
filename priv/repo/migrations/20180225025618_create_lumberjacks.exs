defmodule Sawver.Repo.Migrations.CreateLumberjacks do
  use Ecto.Migration

  def change do
    create table(:lumberjacks, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :color, :string
      add :inventory_id, references(:inventories, type: :uuid, null: false)

      timestamps()
    end

    create index(:lumberjacks, [:inventory_id])
  end
end
