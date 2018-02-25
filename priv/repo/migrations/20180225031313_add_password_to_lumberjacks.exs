defmodule Sawver.Repo.Migrations.AddPasswordToLumberjacks do
  use Ecto.Migration

  def change do
    alter table(:lumberjacks) do
      add :password_digest, :string
    end

    create unique_index(:lumberjacks, [:name])
  end
end
