defmodule Sawver.Inventory do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sawver.Inventory


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "inventories" do
    field :wood, :integer, default: 0
    field :stone, :integer, default: 0
    field :rope, :integer, default: 0
    field :cloth, :integer, default: 0
    field :gold, :integer, default: 0

    field :steel, :integer, default: 0
    field :paper, :integer, default: 0
    field :water, :integer, default: 0
    field :gems, :integer, default: 0
    field :magic, :integer, default: 0

    belongs_to :lumberjack, Sawver.Lumberjack

    timestamps()
  end

  @doc false
  def changeset(%Inventory{} = inventory, params \\ %{}) do
    inventory
    |> cast(params, [:wood, :stone, :rope, :cloth, :gold, :steel, :paper, :water, :gems, :magic])
    |> assoc_constraint(:lumberjack)
  end

  def create_inventory() do
    %Inventory{}
    |> Inventory.changeset()
    |> Sawver.Repo.insert()
    |> case do
        {:ok, data} ->
          data.id
        _ ->
          nil
        end
  end
end
