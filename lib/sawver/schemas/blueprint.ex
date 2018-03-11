defmodule Sawver.Blueprint do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sawver.Blueprint


  schema "blueprints" do
    field :description, :string
    field :display_name, :string
    field :durability, :float
    field :effect_name, :string
    field :gfx_name, :string
    field :mat_cost, :map
    field :req_skills, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(%Blueprint{} = blueprint, attrs) do
    blueprint
    |> cast(attrs, [:display_name, :gfx_name, :effect_name, :mat_cost, :description, :req_skills, :durability])
    |> validate_required([:display_name, :gfx_name, :effect_name, :mat_cost, :description, :req_skills, :durability])
  end

  def get_blueprint(gfx_name) do
    Sawver.Blueprint
    |> Sawver.Repo.get_by([gfx_name: gfx_name])
  end

  def get_cost(gfx_name) do
    get_blueprint(gfx_name)
    |> Map.fetch!(:mat_cost)
    |> Map.new(fn({k, v}) -> {String.to_atom(k), v} end)
  end

  def get_req_skills(gfx_name) do
    get_blueprint(gfx_name)
    |> Map.fetch!(:req_skills)
  end

  def insert_initial_building_values() do
    Sawver.Repo.delete_all(Sawver.Blueprint)

    initial_prints = [
      %{display_name: "Campfire", gfx_name: "campfire", effect_name: "campfire", mat_cost: %{wood: 50}, description: "The extra light helps nearby lumberjacks find more materials when chopping down trees.", req_skills: ["buildFire"], durability: 10.0},
      %{display_name: "Well", gfx_name: "well", effect_name: "well", mat_cost: %{wood: 150}, description: "Produces water once in a while.", req_skills: ["buildWell"], durability: 10.0},
      %{display_name: "Tent", gfx_name: "tent", effect_name: "tent", mat_cost: %{cloth: 100, rope: 25}, description: "Lumberjacks nearby will feel rested, allowing them to walk faster.", req_skills: ["buildTent"], durability: 10.0},
      %{display_name: "Paper Mill", gfx_name: "papermill", effect_name: "papermill", mat_cost: %{wood: 250, water: 250}, description: "Produces paper once in a while.", req_skills: ["buildPapermill"], durability: 1.0},
      %{display_name: "Stone Mine",gfx_name: "mine_stone", effect_name: "mine_stone", mat_cost: %{wood: 750, water: 150}, description: "Produces stone once in a while.", req_skills: ["buildStoneMine"], durability: 10.0},
      %{display_name: "Oven", gfx_name: "oven", effect_name: "oven", mat_cost: %{wood: 400, paper: 400}, description: "Lumberjacks nearby will feel full of energy, allowing them to chop faster.", req_skills: ["buildOven"], durability: 10.0},
      %{display_name: "Beacon", gfx_name: "beacon", effect_name: "beacon", mat_cost: %{wood: 750, magic: 450}, description: "This will help other lumberjacks find you.", req_skills: ["buildBeacon"], durability: 10.0},
      %{display_name: "Gold Mine", gfx_name: "mine_gold", effect_name: "mine_gold", mat_cost: %{stone: 250, gems: 50, water: 350}, description: "Produces gold once in a while.", req_skills: ["buildGoldMine"], durability: 10.0}
    ]
    |> Enum.map(fn(row) ->
      row
      |> Map.put(:inserted_at, DateTime.utc_now)
      |> Map.put(:updated_at, DateTime.utc_now)
      end)
    Sawver.Repo.insert_all(Sawver.Blueprint, initial_prints)
  end

  def get_blueprint_list_for_player() do
    Sawver.Repo.all(Sawver.Blueprint)
    |> Enum.map(fn(sb) -> Map.take(sb, [:display_name, :gfx_name, :mat_cost, :description, :req_skills]) end)
  end
end
