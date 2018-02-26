defmodule Sawver.Lumberjack do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt
  alias Sawver.Lumberjack


  @primary_key {:id, :binary_id, autogenerate: true}
  schema "lumberjacks" do
    field :name, :string
    field :password, :string, virtual: true
    field :password_digest, :string
    field :color, :string
    has_one :inventory, Sawver.Inventory, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(%Lumberjack{} = lumberjack, attrs) do
    lumberjack
    |> cast(attrs, [:name, :password, :color, :inventory_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 3, max: 20)
    |> validate_length(:password, min: 6)
    |> put_pass_digest()
  end

  @doc false
  def registration_changeset(%Lumberjack{} = lumberjack, attrs) do
    lumberjack
    |> Map.put(:inventory, %Sawver.Inventory{})
    |> cast(attrs, [:name, :password, :color])
    |> validate_required([:name, :password, :color])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 3, max: 20)
    |> validate_length(:password, min: 6)
    |> put_pass_digest()
  end

  # Just used until I get actual log-in working.
  def fake_register_changeset(%Lumberjack{} = lumberjack, attrs) do
    lumberjack
    |> Map.put(:inventory, %Sawver.Inventory{})
    |> Map.put(:color, "red")
    |> cast(attrs, [:name])
    |> unique_constraint(:name)
  end

  def create_lumberjack(attrs \\ %{}) do
    %Lumberjack{}
    |> Lumberjack.fake_register_changeset(attrs)
    |> Sawver.Repo.insert()
  end

  def create_lumberjack_if_does_not_exist(name) do
    Lumberjack
    |> Sawver.Repo.get_by([name: name])
    |> case do
        nil ->
          create_lumberjack(%{name: name})
        _ ->
          nil
        end
  end

  defp put_pass_digest(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} -> 
        put_change(changeset, :password_digest, hashpwsalt(pass))
    _ ->
      changeset
    end
  end

  # TODO: There should be a more generic function for grabbing params, but whatever for now.
  def get_lumberjack_color(name) do
    Lumberjack
    |> Sawver.Repo.get_by([name: name])
    |> case do
        nil ->
          "yellow"
        result ->
          result.color
        end
  end

  def get_inventory(name) do
    Lumberjack
    |> Sawver.Repo.get_by([name: name])
    |> Sawver.Repo.preload(:inventory)
    |> Map.fetch!(:inventory)
    |> Map.take([:wood, :stone, :steel, :rope, :cloth, :water, :magic, :paper, :gems, :gold])
  end

  def add_to_inventory(name, type, count) do
    inventory = get_inventory(name)

    Lumberjack
    |> Sawver.Repo.get_by([name: name])
    |> Sawver.Repo.preload(:inventory)
    |> Map.fetch!(:inventory)
    |> Sawver.Inventory.changeset(%{type => inventory.wood + count})
    |> Sawver.Repo.update!()
  end
end
