defmodule Sawver.Terrain do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key  {:id, :binary_id, autogenerate: true}
  schema "terrain" do
    field :xCoord, :integer
    field :yCoord, :integer
    field :object, :string

    timestamps
  end

  def changeset(terrain, params \\ %{}) do
    terrain
    |> cast(params, [:xCoord, :yCoord, :object])
    |> validate_required([:xCoord, :yCoord])
  end
end