defmodule SawverWeb.PlayerChannel do
  use SawverWeb, :channel
  use Bitwise
  import Sawver.HexUtils
  alias Sawver.Presence

  # Maybe subtopic would be good for different zones, if this game had multiple zones...?
  def join("player:position", _payload, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} = Presence.track(socket, socket.assigns.username, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  # Probably didn't need its own message in hindsight. Could have all happened in join, right?
  def handle_in("wake_up", _payload, socket) do
    socket = socket
    |> assign(:x, :rand.uniform(2000) - 1000)
    |> assign(:y, :rand.uniform(2000) - 1000)
    |> assign(:updated_at, System.system_time(:milliseconds))
    Sawver.Agents.Players.put(socket)

    player_grid_pos = get_grid_pos_for_object(socket.assigns)

    %{"x" => player_grid_pos.x, "y" => player_grid_pos.y}
    |> get_neighbors()
    |> Enum.each(fn(n) -> Sawver.Terrain.set_object(Map.put(n, "object", "dirt")) end)
    Sawver.Terrain.set_object(%{"x" => player_grid_pos.x, "y" => player_grid_pos.y, "object" => "dirt"})

    push(socket, "skill_info", %{ skills: Sawver.SkillBook.get_skill_list_for_player() })
    push(socket, "building_info", %{ buildings: Sawver.Blueprint.get_blueprint_list_for_player() })
    broadcast_nearby(socket, "np", %{ :username => socket.assigns.username, :x => socket.assigns.x, :y => socket.assigns.y, :color => get_color(socket) })
    # Probably should not broadcast these? Wait until we need to know before asking.
    broadcast_nearby(socket, "invup", %{ :username => socket.assigns.username, :inventory => get_inventory(socket) })
    broadcast_nearby(socket, "skill_update", %{ :username => socket.assigns.username, :skills => get_skills(socket), :skill_points => get_skill_points(socket) })
    {:noreply, socket}
  end

  # Update for if the player is moving
  def handle_in("rp", %{"current" => current, "desired" => desired}, socket) do
    nearby_buildings = Sawver.Agents.Buildings.filter_nearby(socket)
    speed_mult = case Enum.any?(nearby_buildings, &(&1.effect == "buffwalk")) do
      true -> 2 # 1.5 probably better for real life, this is good for demo
      false -> 1
    end

    move_player(current, desired, get_elapsed_since_update(socket) * speed_mult)
    |> send_position(socket)
  end

  # Update for if the player is static (heartbeat)
  def handle_in("rp", %{}, socket) do
    send_position(%{"x" => socket.assigns.x, "y" => socket.assigns.y}, socket)
  end

  # Well, this certainly doesn't belong in a channel about position...
  def handle_in("buy_skill", %{"skill" => skill}, socket) do
    skill_book = Sawver.SkillBook.get_skillbook(skill)

    !Enum.member?(socket.assigns.lumberjack.skills, skill) and
      socket.assigns.lumberjack.skill_points >= skill_book.cost and
      Enum.all?(skill_book.prereqs, fn(pr) -> Enum.member?(socket.assigns.lumberjack.skills, pr) end)
    |> case do
      true ->
        Sawver.Lumberjack.add_skill(socket.assigns.username, skill)
        Sawver.Lumberjack.add_skill_points(socket.assigns.username, -skill_book.cost)
        socket = assign(socket, :lumberjack, Sawver.Lumberjack.get(socket.assigns.username))
        broadcast_nearby(socket, "skill_update", %{ :username => socket.assigns.username, :skills => get_skills(socket), :skill_points => get_skill_points(socket) })
      false -> nil
    end

    {:noreply, socket}
  end

  defp send_position(pos, socket) do
    current_time = System.system_time(:milliseconds)

    socket = socket
    |> assign(:x, pos["x"])
    |> assign(:y, pos["y"])
    |> assign(:updated_at, current_time)
    
    harvest_resources(socket, current_time)

    # Update socket stored in players agent?
    Sawver.Agents.Players.put(socket)

    broadcast_nearby(socket, "np", Map.put(pos, :username, socket.assigns.username))
    {:noreply, socket}
  end
  
  defp move_player(current_pos, desired_dir, elapsed_time) do
    # Faster to do a comparison to check for idle vs sqrt?
    delta_len = :math.sqrt(desired_dir["x"] * desired_dir["x"] + desired_dir["y"] * desired_dir["y"])
    get_new_position(current_pos, desired_dir, delta_len, elapsed_time)
  end

  defp get_new_position(current_pos, _delta, 0.0, _elapsed) do
    current_pos
  end

  @default_speed 130
  defp get_new_position(current_pos, delta, delta_len, elapsed_time) do
    # TODO: Movement should be time based on not network-message-frame-based
    Enum.map(delta, fn({k, v}) -> {k, v / delta_len} end)
    |> Enum.map(fn({k, v}) -> {k, v * min(@default_speed * elapsed_time, delta_len)} end)
    |> Enum.map(fn({k, v}) -> {k, v + current_pos[k]} end)
    |> Enum.into(%{})
  end

  defp get_color(socket) do
    case socket.assigns.lumberjack do
      nil ->
        "yellow"
      result ->
        result.color
      end
  end

  defp get_inventory(socket) do
    socket.assigns.lumberjack
    |> Map.fetch!(:inventory)
    |> Map.take([:wood, :stone, :steel, :rope, :cloth, :water, :magic, :paper, :gems, :gold])
  end

  defp get_skills(socket) do
    socket.assigns.lumberjack
    |> Map.fetch!(:skills)
  end

  defp get_skill_points(socket) do
    socket.assigns.lumberjack
    |> Map.fetch!(:skill_points)
  end

  defp get_elapsed_since_update(socket) do
    (System.system_time(:milliseconds) - socket.assigns.updated_at) / 1000
  end

  defp broadcast_nearby(socket, msg_name, payload) do
    Sawver.Agents.Players.filter_nearby(socket)
    |> Enum.each(fn(socket) -> push(socket, msg_name, payload) end)
  end

  defp harvest_resources(socket, current_time) do
    # Check to see if we have any buildings nearby that produce stuff
    Sawver.Agents.Buildings.filter_production_nearby(socket, current_time)
    # if there are, see if they are READY to produce stuff
    |> Enum.filter(fn(building) -> (current_time - building.last_harvest_at) / 1000 >= building.production_rate end)
    # if they are, spawn as many resources as it can {{floor((current_time - last_harvest_at) / production_rate)}}
    # Then send out the information below (spawn resources and update inventory)
    |> Enum.each(fn(building) ->
      "produce" <> type = building.effect
      gathered_resources = [%{"type" => type, "count" => trunc(((current_time - building.last_harvest_at) / 1000) / building.production_rate)}]
      
      SawverWeb.Endpoint.broadcast!("object:all", "spawn_resource", %{"user_to_pickup" => socket.assigns.username, "spawn_pos" => get_grid_pos_for_object(building), "resources" => gathered_resources})
      # Would be nice if these could all be updated at once instead of hitting the DB separately, but that sounds like a future Mike problem.
      gathered_resources
      |> Enum.each(fn(gathered) -> 
        Sawver.Lumberjack.add_to_inventory(socket.assigns.username, String.to_atom(gathered["type"]), gathered["count"])
      end)

      broadcast_nearby(socket, "invup", %{ :username => socket.assigns.username, :inventory => Sawver.Lumberjack.get_inventory(socket.assigns.username) })
    end)
  end

  # Should be in hexutils
  defp get_grid_pos_for_object(obj) do
    grid_y = trunc((obj.y - 16)/32)
    case grid_y &&& 1 do
      1 -> %{x: trunc((obj.x - 16)/32), y: grid_y}
      0 -> %{x: trunc((obj.x)/32), y: grid_y}
    end
  end
end