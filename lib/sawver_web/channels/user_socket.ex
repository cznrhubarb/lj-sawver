defmodule SawverWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  # channel "room:*", SawverWeb.RoomChannel
  channel "object:*", SawverWeb.ObjectChannel
  channel "player:*", SawverWeb.PlayerChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    timeout: 45_000
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"username" => username}, socket) do
    {:ok, socket
      |> assign(:lumberjack, Sawver.Lumberjack.create_lumberjack_if_does_not_exist(username))
      |> assign(:username, username)
      |> apply_skills()
    }
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     SawverWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil

  # Wish this didn't have to go here. Starting to feel like the different channels should all be
  #  in one channel instead, butthat definitely seems wrong...  
  defp apply_skills(socket) do
    applied_skills = socket.assigns.lumberjack.skills
    |> Enum.filter(fn(skill) -> 
      case skill do
        "gather" <> _resource -> true
        "track" <> _object -> true
        _ -> false
      end
    end)
    |> Enum.map(fn(skill) ->
      {String.downcase(skill), Sawver.SkillBook.get_skillbook(skill) |> Map.fetch!(:effect_value)}
    end)
    |> Map.new()

    assign(socket, :applied_effects, applied_skills)
  end
end
