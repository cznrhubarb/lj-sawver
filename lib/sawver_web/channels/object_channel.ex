defmodule SawverWeb.ObjectChannel do
  use SawverWeb, :channel

  def join("object:all", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("set_obj_at", obj_list, socket) do
    # TODO: Still overwriting existing things...
    Enum.each(obj_list["objects"], &set_object/1)
    broadcast(socket, "get_obj_response", obj_list)
    {:noreply, socket}
  end

  def handle_in("chop", location, socket) do
    # TODO: I think this chop is coming in more than once?
    wood_collected = :rand.uniform(3) - 1
    location
    |> find_object()
    |> case do
      "tree" ->
        obj = location
        |> Map.put("object", "stump")
        set_object(obj)
        broadcast(socket, "get_obj_response", %{objects: [obj]})
        broadcast(socket, "spawn_resource", %{"user_to_pickup" => socket.assigns.username, "spawn_pos" => location, "resources" => [%{"type" => "wood", "count" => wood_collected}]})

        Sawver.Lumberjack.add_to_inventory(socket.assigns.username, :wood, wood_collected)

        # This is totes not the way to do this
        SawverWeb.Endpoint.broadcast!("player:position", "inventory_update", %{ :username => socket.assigns.username, :inventory => Sawver.Lumberjack.get_inventory(socket.assigns.username) })
      _ ->
        nil
      end
    {:noreply, socket}
  end

  def handle_in("get_obj_at", obj_coord_list, socket) do
    obj_list = Enum.map(obj_coord_list["coords"], fn(coords) -> %{"x" => coords["x"], "y" => coords["y"], "object"=> find_object(coords)} end)
    push(socket, "get_obj_response", %{:objects => obj_list})
    {:noreply, socket}
  end

  defp set_object(obj) do
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

  defp find_object(coords) do
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
end