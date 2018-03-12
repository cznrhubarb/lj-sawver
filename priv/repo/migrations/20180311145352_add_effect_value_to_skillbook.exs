defmodule Sawver.Repo.Migrations.AddEffectValueToSkillbook do
  use Ecto.Migration

  def change do
    alter table(:skill_books) do
      add :effect_value, :float
    end
  end
end
