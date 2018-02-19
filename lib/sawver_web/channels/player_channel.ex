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
    # TODO: Can start player aaaaaaanywhere now
    # TODO: Need to add the logic to make sure they don't start on top of each other
    broadcast(socket, "new_position", %{ :username => socket.assigns.username, :x => :rand.uniform(800), :y => :rand.uniform(600) })
    {:noreply, socket}
  end

  def handle_in("req_position", %{"current" => current, "desired" => desired}, socket) do
    # Current pos probably needs to be held server side? But how to do that stateless?
    new_pos = move_player(current, desired)
    broadcast(socket, "new_position", Map.put(new_pos, :username, socket.assigns.username))
    {:noreply, socket}
  end

  def handle_in("req_position", %{"current" => current}, socket) do
    # Current pos probably needs to be held server side? But how to do that stateless?
    broadcast(socket, "new_position", Map.put(current, :username, socket.assigns.username))
    {:noreply, socket}
  end
  
  defp move_player(current_pos, desired_pos) do
    delta = %{ "x" => desired_pos["x"] - current_pos["x"], "y" => desired_pos["y"] - current_pos["y"] }
    delta_len = :math.sqrt(delta["x"] * delta["x"] + delta["y"] * delta["y"])
    get_new_position(current_pos, delta, delta_len)
  end

  defp get_new_position(current_pos, _delta, 0.0) do
    current_pos
  end

  defp get_new_position(current_pos, delta, delta_len) do
    Enum.map(delta, fn({k, v}) -> {k, v / delta_len} end)
    |> Enum.map(fn({k, v}) -> {k, v * min(3, delta_len)} end)
    |> Enum.map(fn({k, v}) -> {k, v + current_pos[k]} end)
    |> Enum.into(%{})
  end
end