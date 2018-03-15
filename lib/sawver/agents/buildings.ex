defmodule Sawver.Agents.Buildings do
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def put(building) do
    Agent.update(__MODULE__, fn(state) ->
      building = case building.effect do
        "produce" <> _type -> Map.put(building, :last_harvest_at, System.system_time(:milliseconds))
        _ -> building
      end
      state ++ [building]
    end)
  end

  @aura_aabb_size 1500
  def filter_nearby(player_socket) do
    pos_sock = Sawver.Agents.Players.get(player_socket.assigns.username)
    Agent.get(__MODULE__, fn(state) ->
      Enum.filter(state, fn(building) -> is_nearby(pos_sock.assigns, building, @aura_aabb_size) end)
    end)
  end

  @production_aabb_size 150
  # Very side-effecty, unidiomatic function
  def filter_production_nearby(player_socket, current_time) do
    pos_sock = Sawver.Agents.Players.get(player_socket.assigns.username)
    ret_val = Agent.get(__MODULE__, fn(state) ->
      Enum.filter(state, fn(building) -> is_nearby(pos_sock.assigns, building, @production_aabb_size) and is_production(building) end)
    end)

    # this is the one of the worst elixir functions ever written
    Agent.update(__MODULE__, fn(state) ->
      Enum.map(state, fn(building) -> 
        case is_nearby(pos_sock.assigns, building, @production_aabb_size) and is_production(building) do
          false -> building
          true -> 
            prod_in_millis = building.production_rate * 1000
            Map.update!(building, :last_harvest_at, &(&1 + (trunc((current_time - &1) / prod_in_millis) * prod_in_millis)))
        end
      end)
    end)

    # so gross
    ret_val
  end

  def is_nearby(player, building, distance) do
    player.x >= building.x - distance and
      player.x < building.x + distance and
      player.y >= building.y - distance and
      player.y < building.y + distance
  end

  defp is_production(building) do
    case building.effect do
      "produce" <> _ -> true
      _ -> false
    end
  end
end