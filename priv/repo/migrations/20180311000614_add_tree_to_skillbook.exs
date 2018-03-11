defmodule Sawver.Repo.Migrations.AddTreeToSkillbook do
  use Ecto.Migration

  def change do
    alter table(:skill_books) do
      add :tree, :string
    end
  end
end
