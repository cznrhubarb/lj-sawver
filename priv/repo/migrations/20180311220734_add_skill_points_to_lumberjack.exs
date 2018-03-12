defmodule Sawver.Repo.Migrations.AddSkillPointsToLumberjack do
  use Ecto.Migration

  def change do
    alter table(:lumberjacks) do
      add :skill_points, :integer
      add :xp, :integer
    end
  end
end
