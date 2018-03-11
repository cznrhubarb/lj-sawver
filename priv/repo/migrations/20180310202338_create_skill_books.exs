defmodule Sawver.Repo.Migrations.CreateSkillBooks do
  use Ecto.Migration

  def change do
    create table(:skill_books) do
      add :name, :string
      add :type, :string
      add :description, :string
      add :prereqs, {:array, :string}
      add :cost, :integer
      add :cooldown, :float

      timestamps()
    end

  end
end
