defmodule Sawver.Inventory do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sawver.Inventory


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "inventories" do
    field :items, :map

    timestamps()
  end

  @doc false
  def changeset(%Inventory{} = inventory, attrs) do
    inventory
    |> cast(attrs, [:items])
    |> validate_required([:items])
  end
end
