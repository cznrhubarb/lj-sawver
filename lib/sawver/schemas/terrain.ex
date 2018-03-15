defmodule Sawver.Terrain do
  use Ecto.Schema
  import Ecto.Changeset
  import Sawver.HexUtils

  @primary_key  {:id, :binary_id, autogenerate: true}
  schema "terrain" do
    field :xCoord, :integer
    field :yCoord, :integer
    field :object, :string

    timestamps()
  end

  def changeset(terrain, params \\ %{}) do
    terrain
    |> cast(params, [:xCoord, :yCoord, :object])
    |> validate_required([:xCoord, :yCoord])
  end

  
  def set_object(obj) do
    case Sawver.Repo.get_by(Sawver.Terrain, [xCoord: obj["x"], yCoord: obj["y"]]) do
      nil -> %Sawver.Terrain{xCoord: obj["x"], yCoord: obj["y"], object: obj["object"]}
      ter -> %{ter | object: obj["object"]}
    end
    |> Sawver.Terrain.changeset
    |> Sawver.Repo.insert_or_update
    # Just return the same object so we can use it for other things
    # TODO: Probably should return a status
    obj
  end

  def find_object(coords) do
    Sawver.Terrain
    |> Sawver.Repo.get_by([xCoord: coords["x"], yCoord: coords["y"]])
    |> obj_type_from_query_result
    # TODO: Need split the load on this? Can't have all objects ever from one server
  end

  defp obj_type_from_query_result(nil) do
    "tree"
  end

  defp obj_type_from_query_result(result) do
    Map.fetch!(result, :object)
  end

  # Buildable areas consist of only stumps or dirt.
  # Assume the radius on all builds is one hex for now.
  def buildable_area?(location) do
    location
    |> get_neighbors()
    |> Enum.all?(fn(n) -> find_object(n) |> is_cleared end)
  end

  defp is_cleared(obj_type) do
    case obj_type do
      "stump" -> true
      "dirt" -> true
      _ -> false
    end
  end

  def spawn_a_bunch_of_things(type, 0) do
    IO.puts("done inserting " <> type)
  end
  
  def spawn_a_bunch_of_things(type, how_many_more) do
    xCoord = :rand.uniform(3000) - 1500
    yCoord = :rand.uniform(3000) - 1500
    spawned_obj = %{"x" => xCoord, "y" => yCoord, "object" => type}

    #spawned_obj 
    #|> get_neighbors() 
    #|> Enum.each(fn(n) -> set_object(Map.put(n, "object", "dirt")) end)

    set_object(spawned_obj)
    spawn_a_bunch_of_things(type, how_many_more - 1)
  end
end