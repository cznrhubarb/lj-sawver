defmodule SawverWeb.ObjectChannel do
  import Sawver.Terrain
  import Sawver.HexUtils
  import Sawver.Lumberjack
  import Sawver.Blueprint
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

  def handle_in("build", build_params, socket) do
    build_params
    |> check_build_skill(socket.assigns.username)
    |> check_build_area()
    |> check_build_cost(socket.assigns.username)
    |> build(socket)

    {:noreply, socket}
  end

  def handle_in("get_obj_at", obj_coord_list, socket) do
    obj_list = Enum.map(obj_coord_list["coords"], fn(coords) -> %{"x" => coords["x"], "y" => coords["y"], "object"=> find_object(coords)} end)
    push(socket, "get_obj_response", %{:objects => obj_list})
    {:noreply, socket}
  end

  def check_build_skill({:error, msg}, _), do: {:error, msg}
  def check_build_skill(build_params, name) do
    has_skill_to_build?(name, get_req_skills(build_params["object"]))
    |> case do
      true -> build_params
      _ -> {:error, "You don't have the skill needed to build that."}
      end
  end

  def check_build_area({:error, msg}), do: {:error, msg}
  def check_build_area(build_params) do
    buildable_area?(build_params)
    |> case do
      true -> build_params
      _ -> {:error, "Something is in the way. You can't build there."}
      end
  end

  def check_build_cost({:error, msg}, _), do: {:error, msg}
  def check_build_cost(build_params, name) do
    can_pay_cost?(name, get_cost(build_params["object"]))
    |> case do
      true -> build_params
      _ -> {:error, "You don't have the materials needed to build that."}
      end
  end

  def build({:error, msg}, socket) do
    push(socket, "build_failed", %{reason: msg})
  end

  def build(build_params, socket) do
    dirt_list = build_params
    |> get_neighbors()
    |> Enum.map(fn(hex) -> Map.put(hex, "object", "dirt") end)
    |> Enum.map(&set_object/1)
    broadcast(socket, "get_obj_response", %{objects: [set_object(build_params) | dirt_list]})
    
    subtract_cost(socket.assigns.username, get_cost(build_params["object"]))
    # 🎵 Oops, I did it again. 🎵
    SawverWeb.Endpoint.broadcast!("player:position", "inventory_update", %{ :username => socket.assigns.username, :inventory => Sawver.Lumberjack.get_inventory(socket.assigns.username) })
  end
end