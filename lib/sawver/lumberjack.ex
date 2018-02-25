defmodule Sawver.Lumberjack do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt
  alias Sawver.Lumberjack


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "lumberjacks" do
    field :name, :string
    field :password, :string, virtual: true
    field :password_digest, :string
    field :color, :string
    field :inventory, :id

    timestamps()
  end

  @doc false
  def changeset(%Lumberjack{} = lumberjack, attrs) do
    lumberjack
    |> cast(attrs, [:name, :password, :color, :inventory])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 3, max: 20)
    |> validate_length(:password, min: 6)
    |> put_pass_digest()
  end

  @doc false
  def registration_changeset(%Lumberjack{} = lumberjack, attrs) do
    lumberjack
    |> cast(attrs, [:name, :password, :color])
    |> validate_required([:name, :password, :color])
    |> unique_constraint(:name)
    |> validate_length(:name, min: 3, max: 20)
    |> validate_length(:password, min: 6)
    |> put_pass_digest()
  end

  defp put_pass_digest(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} -> 
        put_change(changeset, :password_digest, Comeonin.Bcrypt.hashpwsalt(pass))
    _ ->
      changeset
    end
  end
end
