defmodule Sawver.HexUtils do
  use Bitwise
  
  def offset_distance(hexA, hexB) do
    cube_distance(offset_to_cube(hexA), offset_to_cube(hexB))
  end

  def neighbors?(hexA, hexB) do
    offset_distance(hexA, hexB) == 1
  end

  defp cube_distance(hexA, hexB) do
    (abs(hexA["x"] - hexB["x"]) + abs(hexA["y"] - hexB["y"]) + abs(hexA["z"] - hexB["z"])) / 2
  end

  defp offset_to_cube(hex) do
    x = hex["x"] - div(hex["y"] - (hex["y"] &&& 1), 2)
    y = -x - hex["y"]
    %{"x" => x, "y" => y, "z" => hex["y"]}
  end

  defp cube_to_offset(hex) do
    x = hex["x"] + div(hex["z"] - (hex["z"] &&& 1), 2)
    %{"x" => x, "y" => hex["z"]}
  end

  # Takes an odd-r offset hex and returns the six neighbor hexes in the same format
  def get_neighbors(hex) do
    cube = offset_to_cube(hex)
    [%{"x" => 1, "y" => 0, "z" => -1}, 
     %{"x" => 1, "y" => -1, "z" => 0}, 
     %{"x" => 0, "y" => -1, "z" => 1}, 
     %{"x" => -1, "y" => 0, "z" => 1}, 
     %{"x" => -1, "y" => 1, "z" => 0}, 
     %{"x" => 0, "y" => 1, "z" => -1}]
    |> Enum.map(fn(offset) -> Map.merge(cube, offset, fn(_k, v1, v2) -> v1 + v2 end) end)
    |> Enum.map(fn(neighbor) -> cube_to_offset(neighbor) end)
  end
end