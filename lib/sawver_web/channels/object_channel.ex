defmodule SawverWeb.ObjectChannel do
  use SawverWeb, :channel

  def join("object:all", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("get_obj_at", obj_coord_list, socket) do
    obj_list = Enum.map(obj_coord_list["coords"], fn(coords) -> %{"x" => coords["x"], "y" => coords["y"], "object"=> find_object(coords)} end)
    push(socket, "get_obj_response", %{:objects => obj_list})
    {:noreply, socket}
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