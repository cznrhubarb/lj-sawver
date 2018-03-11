defmodule SawverWeb.PlayerChannel do
  use SawverWeb, :channel
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

  def handle_in("wake_up", _payload, socket) do
    socket = socket
    |> assign(:x, :rand.uniform(10000) - 5000)
    |> assign(:y, :rand.uniform(10000) - 5000)
    |> assign(:updated_at, System.system_time(:milliseconds))
    push(socket, "skill_info", %{ skills: Sawver.SkillBook.get_skill_list_for_player() })
    push(socket, "building_info", %{ buildings: Sawver.Blueprint.get_blueprint_list_for_player() })
    broadcast(socket, "new_position", %{ :username => socket.assigns.username, :x => socket.assigns.x, :y => socket.assigns.y, :color => get_color(socket) })
    # Probably should not broadcast these? Wait until we need to know before asking.
    broadcast(socket, "inventory_update", %{ :username => socket.assigns.username, :inventory => get_inventory(socket) })
    broadcast(socket, "skill_update", %{ :username => socket.assigns.username, :skills => get_skills(socket) })
    {:noreply, socket}
  end

  # Update for if the player is moving
  def handle_in("req_position", %{"current" => current, "desired" => desired}, socket) do
    move_player(current, desired, get_elapsed_since_update(socket))
    |> send_position(socket)
  end

  # Update for if the player is static (heartbeat)
  def handle_in("req_position", %{"current" => current}, socket) do
    send_position(current, socket)
  end

  defp send_position(pos, socket) do
    # Current pos probably needs to be held server side? But how to do that stateless?
    socket = socket
    |> assign(:x, pos["x"])
    |> assign(:y, pos["y"])
    |> assign(:updated_at, System.system_time(:milliseconds))
    broadcast(socket, "new_position", Map.put(pos, :username, socket.assigns.username))
    {:noreply, socket}
  end
  
  defp move_player(current_pos, desired_dir, elapsed_time) do
    delta_len = :math.sqrt(desired_dir["x"] * desired_dir["x"] + desired_dir["y"] * desired_dir["y"])
    get_new_position(current_pos, desired_dir, delta_len, elapsed_time)
  end

  defp get_new_position(current_pos, _delta, 0.0, _elapsed) do
    current_pos
  end

  defp get_new_position(current_pos, delta, delta_len, elapsed_time) do
    # TODO: Movement should be time based on not network-message-frame-based
    Enum.map(delta, fn({k, v}) -> {k, v / delta_len} end)
    |> Enum.map(fn({k, v}) -> {k, v * min(130 * elapsed_time, delta_len)} end)
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
    #Sawver.Lumberjack.get_inventory(socket.assigns.username)
    socket.assigns.lumberjack
    |> Map.fetch!(:inventory)
    |> Map.take([:wood, :stone, :steel, :rope, :cloth, :water, :magic, :paper, :gems, :gold])
  end

  defp get_skills(socket) do
    socket.assigns.lumberjack
    |> Map.fetch!(:skills)
  end

  defp get_elapsed_since_update(socket) do
    (System.system_time(:milliseconds) - socket.assigns.updated_at) / 1000
  end
end