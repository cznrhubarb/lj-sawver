use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :default,
    # This sets the default environment used by `mix release`
    default_environment: :dev

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/configuration.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"*8ooQ~HYj90[*ZL}pGn?[C4@c{nQkz3vI.}@cleu>94ycX}N@k27<XHhU><D%Z)N"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"!?*0{9?>@hI*4u|D;t?Mc4>y$ki!vPkD;G=~vcc%auUDeO1kv]PF)l{miMf@&T$<"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :sawver do
  set version: current_version(:sawver)
end

