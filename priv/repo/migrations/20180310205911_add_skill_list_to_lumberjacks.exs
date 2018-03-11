defmodule Sawver.Repo.Migrations.AddSkillListToLumberjacks do
  use Ecto.Migration

  def change do
    alter table(:lumberjacks) do
      add :skills, {:array, :string}
    end
  end
end
