defmodule Sawver.Agents.TerrainCommitQueue do
  def start_link do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def put(x, y, obj_type) do
    Agent.update(__MODULE__, fn(state) ->
      # in this case, we need to commit to db as well
      Map.put(state, x <> "_" <> y, %{"x" => x, "y" => y, "object" => obj_type})
    end)
  end

  def commit_to_db() do
    
  end
end