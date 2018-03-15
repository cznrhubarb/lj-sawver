defmodule Sawver.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    Sawver.Agents.Players.start_link()
    Sawver.Agents.Buildings.start_link()


    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Sawver.Repo, []),
      # Start the endpoint when the application starts
      supervisor(SawverWeb.Endpoint, []),
      
      supervisor(Sawver.Presence, []),
      # Start your own worker by calling: Sawver.Worker.start_link(arg1, arg2, arg3)
      # worker(Sawver.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sawver.Supervisor]
    link = Supervisor.start_link(children, opts)

    # Current super hack: Delete all terrain on server restart
    #   It all would have decayed anyway, right?
    Sawver.Repo.delete_all(Sawver.Terrain)
    # This should be acceptable also, right?
    Sawver.SkillBook.insert_initial_skill_values()
    Sawver.Blueprint.insert_initial_building_values()

    #Sawver.Terrain.spawn_a_bunch_of_things("rockGrey_large", 2500)
    #Sawver.Terrain.spawn_a_bunch_of_things("ruinsCorner", 3000)
    Sawver.Terrain.spawn_a_bunch_of_things("towerRuin", 5000)
    Sawver.Terrain.spawn_a_bunch_of_things("cactus1", 5000)
    Sawver.Terrain.spawn_a_bunch_of_things("skilltree", 20000)
    Sawver.Terrain.spawn_a_bunch_of_things("spaceship", 100)

    # dumb.
    link
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SawverWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
