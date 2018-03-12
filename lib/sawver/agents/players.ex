defmodule Sawver.Agents.Players do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(username) do
    Agent.get(__MODULE__, fn(state) ->
      Map.get(state, username)
    end)
  end

  def put(player_socket) do
    Agent.update(__MODULE__, fn(state) ->
      Map.put(state, player_socket.assigns.username, player_socket)
    end)
  end

  def filter_nearby(player_socket) do
    Agent.get(__MODULE__, fn(state) ->
      Map.values(state)
      |> Enum.filter(fn(socket) -> is_nearby(player_socket, socket) end)
    end)
  end

  # Think this aabb size should be adjusted based on the tracking skills of the sock_two (player being sent the update)
  @aabb_size 3000
  defp is_nearby(sock_one, sock_two) do
    sock_one.assigns.x >= sock_two.assigns.x - @aabb_size and
      sock_one.assigns.x < sock_two.assigns.x + @aabb_size and
      sock_one.assigns.y >= sock_two.assigns.y - @aabb_size and
      sock_one.assigns.y < sock_two.assigns.y + @aabb_size
  end
end