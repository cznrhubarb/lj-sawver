defmodule SawverWeb.ObjectChannel do
  use SawverWeb, :channel

  def join("object:stump", payload, socket) do
    {:ok, socket}
  end

  def handle_in("create_stump", payload, socket) do
    IO.puts("Reloaded!!!")
    broadcast(socket, "create_stump_res", payload)
    {:noreply, socket}
  end
end