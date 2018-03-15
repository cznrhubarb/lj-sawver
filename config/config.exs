# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :sawver,
  ecto_repos: [Sawver.Repo]

# Configures the endpoint
config :sawver, SawverWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "KQUE/G19uPLnO3OXisO8dDa89SzFS5Rp4FgK63ui2zYbBs8OPaGvy2E7omIX6PSJ",
  render_errors: [view: SawverWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Sawver.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  compile_time_purge_level: :error,
  level: :error,
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
