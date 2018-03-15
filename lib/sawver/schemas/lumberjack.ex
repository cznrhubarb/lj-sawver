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
    field :skills, {:array, :string}
    field :skill_points, :integer
    field :xp, :integer
    has_one :inventory, Sawver.Inventory, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(%Lumberjack{} = lumberjack, attrs \\ %{}) do
    lumberjack
    |> cast(attrs, [:name, :password, :color, :skills, :skill_points, :xp])
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
    |> cast(attrs, [:name, :password, :color, :skills, :skill_points, :xp])
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
    |> Map.put(:color, get_random_color())
    |> Map.put(:skills, [])
    |> Map.put(:skill_points, 6)
    |> Map.put(:xp, 0)
    |> cast(attrs, [:name])
    |> unique_constraint(:name)
  end

  defp get_random_color() do
    Enum.random(["red", "blue", "yellow", "green"])
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
        lj ->
          lj
        end
    |> Sawver.Repo.preload(:inventory)
  end

  defp put_pass_digest(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} -> 
        put_change(changeset, :password_digest, hashpwsalt(pass))
    _ ->
      changeset
    end
  end

  def get(name) do
    Lumberjack
    |> Sawver.Repo.get_by([name: name])
    |> Sawver.Repo.preload(:inventory)
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
    |> Sawver.Inventory.changeset(%{type => inventory[type] + count})
    |> Sawver.Repo.update!()
  end

  def add_skill(lumberjack_name, skill_name) do
    lj = Lumberjack
    |> Sawver.Repo.get_by([name: lumberjack_name])
    
    changeset(lj, %{skills: lj.skills ++ [skill_name]})
    |> Sawver.Repo.update!()
  end

  def add_skill_points(lumberjack_name, points) do
    lj = Lumberjack
    |> Sawver.Repo.get_by([name: lumberjack_name])
    
    changeset(lj, %{skill_points: lj.skill_points + points})
    |> Sawver.Repo.update!()
  end

  def has_skill_to_build?(name, skill_list) do
    skills = Lumberjack
    |> Sawver.Repo.get_by([name: name])
    |> Map.fetch!(:skills)
    
    Enum.all?(skill_list, &Enum.member?(skills, &1))
  end

  def can_pay_cost?(name, cost) do
    inventory = get_inventory(name)
    cost
    |> Enum.all?(fn({type, count}) -> inventory[type] >= count end)
  end

  def subtract_cost(name, cost) do
    # TODO: SUPER SLOW WAY OF DOING THIS. FIX THIS WHEN YOU ARE FEELING LESS LAZY
    cost
    |> Enum.each(fn({type, count}) -> add_to_inventory(name, type, -count) end)
  end
end
