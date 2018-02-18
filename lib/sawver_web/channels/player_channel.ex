defmodule SawverWeb.PlayerChannel do
  use SawverWeb, :channel

  # Maybe subtopic would be good for different zones, if this game had multiple zones...?
  def join("player:position", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("wake_up", _payload, socket) do
    broadcast(socket, "new_position", %{ :username => socket.assigns.username, :x => :rand.uniform(800), :y => :rand.uniform(600) })
    {:noreply, socket}
  end

  def handle_in("req_position", payload, socket) do
    # Current pos probably needs to be held server side? But how to do that stateless?
    new_pos = move_player(payload["current"], payload["desired"])
    broadcast(socket, "new_position", Map.put(new_pos, :username, socket.assigns.username))
    {:noreply, socket}
  end
  
  defp move_player(current_pos, desired_pos) do
    delta = %{ "x" => desired_pos["x"] - current_pos["x"], "y" => desired_pos["y"] - current_pos["y"] }
    delta_len = :math.sqrt(delta["x"] * delta["x"] + delta["y"] * delta["y"])

    Enum.map(delta, fn({k, v}) -> {k, v / delta_len} end)
    |> Enum.map(fn({k, v}) -> {k, v * min(3, delta_len)} end)
    |> Enum.map(fn({k, v}) -> {k, v + current_pos[k]} end)
    |> Enum.into(%{})
  end
end