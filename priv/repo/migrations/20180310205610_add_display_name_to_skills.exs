defmodule Sawver.Repo.Migrations.AddDisplayNameToSkills do
  use Ecto.Migration

  def change do
    alter table(:skill_books) do
      add :display_name, :string
    end
  end
end
