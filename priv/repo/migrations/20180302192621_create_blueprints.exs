defmodule Sawver.Repo.Migrations.CreateBlueprints do
  use Ecto.Migration

  def change do
    create table(:blueprints) do
      add :display_name, :string
      add :gfx_name, :string
      add :effect_name, :string
      add :mat_cost, :map
      add :description, :string
      add :req_skills, {:array, :string}
      add :durability, :float

      timestamps()
    end

  end
end
