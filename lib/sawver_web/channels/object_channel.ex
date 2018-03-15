defmodule SawverWeb.ObjectChannel do
  import Sawver.Terrain
  import Sawver.HexUtils
  import Sawver.Lumberjack
  import Sawver.Blueprint
  use SawverWeb, :channel
  use Bitwise

  def join("object:all", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("set_obj_at", obj_list, socket) do
    # TODO: Still overwriting existing things...
    Enum.each(obj_list["objects"], &set_object/1)
    broadcast(socket, "get_obj_response", obj_list)
    {:noreply, socket}
  end

  # All _gathered values are the exclusive range cap for gathering, but it's floating point
  #   ie. 3 means 0, 1, or 2 are possible values, evenly likely to occur
  #       3.3 means 0, 1, 2, or 3 are possible values, but 3 is unlikely
  #   No weighted ranges implemented for now. Just bump it slightly past 1.0 if you want it to be rare
  @default_gathered [%{"type" => "wood", "count" => 3},
                     %{"type" => "cloth", "count" => 0},
                     %{"type" => "rope", "count" => 0},
                     %{"type" => "magic", "count" => 0},
                     %{"type" => "gems", "count" => 0}
                    ]
  def handle_in("chop", location, socket) do
    location
    |> find_object()
    |> case do
      "tree" ->
        cut_down(location, socket)
      "skilltree" ->
        # ugggggghhhhhh
        Sawver.Lumberjack.add_skill_points(socket.assigns.username, 1)
        socket = assign(socket, :lumberjack, Sawver.Lumberjack.get(socket.assigns.username))    
        SawverWeb.Endpoint.broadcast!("player:position", "skill_update", %{ :username => socket.assigns.username, :skills => get_skills(socket), :skill_points => get_skill_points(socket) })
  
        cut_down(location, socket)
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

  defp cut_down(location, socket) do
    obj = location
    |> Map.put("object", "stump")
    |> set_object()
    broadcast(socket, "get_obj_response", %{objects: [obj]})

    gathered_resources = @default_gathered
    |> add_base_rates(socket.assigns.applied_effects)
    |> multiply_modifiers(socket)
    |> get_random_counts()
    |> filter_out_zeros()

    broadcast(socket, "spawn_resource", %{"user_to_pickup" => socket.assigns.username, "spawn_pos" => location, "resources" => gathered_resources})
    # Would be nice if these could all be updated at once instead of hitting the DB separately, but that sounds like a future Mike problem.
    gathered_resources
    |> Enum.each(fn(gathered) -> 
      Sawver.Lumberjack.add_to_inventory(socket.assigns.username, String.to_atom(gathered["type"]), gathered["count"])
    end)

    # This is totes not the way to do this
    SawverWeb.Endpoint.broadcast!("player:position", "invup", %{ :username => socket.assigns.username, :inventory => Sawver.Lumberjack.get_inventory(socket.assigns.username) })
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
    
    bp = get_blueprint(build_params["object"])
    prod_rate = case Map.fetch(bp, :production_rate) do 
      {:ok, rate} -> rate
      :error -> nil
    end
    in_mem_building = get_world_pos_for_object(build_params) 
    |> Map.put(:effect, Map.fetch!(bp, :effect_name))
    |> Map.put(:production_rate, prod_rate) 
    Sawver.Agents.Buildings.put(in_mem_building)
    subtract_cost(socket.assigns.username, get_cost(build_params["object"]))
    # 🎵 Oops, I did it again. 🎵
    SawverWeb.Endpoint.broadcast!("player:position", "invup", %{ :username => socket.assigns.username, :inventory => Sawver.Lumberjack.get_inventory(socket.assigns.username) })
  end

  defp add_base_rates(default_rates, applied_effects) do
    default_rates
    |> Enum.map(fn(rate) -> 
      case Map.fetch(applied_effects, "gather" <> rate["type"]) do
        {:ok, add_rate} -> Map.put(rate, "count", rate["count"] + add_rate)
        :error -> rate
      end
    end)
  end

  defp multiply_modifiers(cumulative_base_rates, socket) do
    cumulative_base_rates
    |> Enum.map(fn(rate) -> 
      case Map.fetch(socket.assigns.applied_effects, "buffchop") do
        {:ok, mult_rate} -> Map.put(rate, "count", rate["count"] * mult_rate)
        :error -> rate
      end
    end)
    |> Enum.map(fn(rate) -> 
      nearby_buildings = Sawver.Agents.Buildings.filter_nearby(socket)
      case Enum.any?(nearby_buildings, &(&1.effect == "buffchop")) do
        #true -> Map.put(rate, "count", rate["count"] * 1.5)   # Would prefer if this rate were stored somewhere on the building data I guess...
        true -> Map.put(rate, "count", rate["count"] * 4)   # More fun number for the demo. Real number should be closer to the 1.5 above.
        false -> rate
      end
    end)
  end

  defp get_random_counts(modified_rates) do
    modified_rates
    |> Enum.map(fn(rate) -> Map.put(rate, "count", trunc(:rand.uniform() * rate["count"])) end)
  end

  defp filter_out_zeros(gathered_resources) do
    gathered_resources
    |> Enum.filter(fn(gathered) -> gathered["count"] > 0 end)
  end

  # Should be in hexutils
  defp get_world_pos_for_object(obj) do
    case obj["y"] &&& 1 do
      1 -> %{x: obj["x"] * 32 + 16, y: obj["y"] * 32}
      0 -> %{x: obj["x"] * 32, y: obj["y"] * 32}
    end
  end

  
  # Duplicating code for the demo. Rush mode =/
  defp get_skills(socket) do
    socket.assigns.lumberjack
    |> Map.fetch!(:skills)
  end

  defp get_skill_points(socket) do
    socket.assigns.lumberjack
    |> Map.fetch!(:skill_points)
  end
end