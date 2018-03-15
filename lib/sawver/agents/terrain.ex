defmodule Sawver.Agents.Terrain do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(x, y) do
    Agent.get(__MODULE__, fn(state) ->
      Map.fetch(state, x <> "_" <> y)
      |> case do
        {:ok, obj_type} -> obj_type
        :error -> 
          obj_type = Sawver.Terrain.find_object(%{"x" => x, "y" => y})
          put(x, y, obj_type)
          obj_type
      end
    end)
  end

  defp put(x, y, obj_type) do
    Agent.update(__MODULE__, fn(state) ->
      Map.put(state, x <> "_" <> y, obj_type)
    end)
  end
end