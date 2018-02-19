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
end