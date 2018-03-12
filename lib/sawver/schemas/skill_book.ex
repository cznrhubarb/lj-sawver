defmodule Sawver.SkillBook do
  use Ecto.Schema
  import Ecto.Changeset
  alias Sawver.SkillBook


  schema "skill_books" do
    field :tree, :string
    field :display_name, :string
    field :name, :string
    field :type, :string
    field :description, :string
    field :prereqs, {:array, :string}
    field :cost, :integer
    field :cooldown, :float
    field :effect_value, :float

    timestamps()
  end

  @doc false
  def changeset(%SkillBook{} = skill_book, attrs) do
    skill_book
    |> cast(attrs, [:tree, :display_name, :name, :type, :description, :prereqs, :cost, :cooldown, :effect_value])
    |> validate_required([:tree, :display_name, :name, :type, :description, :prereqs, :cost])
  end

  def get_skillbook(name) do
    Sawver.SkillBook
    |> Sawver.Repo.get_by([name: name])
  end

  def get_cost(name) do
    get_skillbook(name)
    |> Map.fetch!(:cost)
  end

  def get_prereqs(name) do
    get_skillbook(name)
    |> Map.fetch!(:prereqs)
  end

  def insert_initial_skill_values() do
    Sawver.Repo.delete_all(Sawver.SkillBook)

    initial_books = [
      %{tree: "builder", display_name: "Build Campfire", name: "buildFire", type: "build", description: "Learn how to build a proper campfire.", prereqs: [], cost: 1, cooldown: nil},
      %{tree: "builder", display_name: "Build Well", name: "buildWell", type: "build", description: "Probably should be able to get water to put out those fires.", prereqs: ["buildFire"], cost: 1, cooldown: nil},
      %{tree: "builder", display_name: "Build Tent", name: "buildTent", type: "build", description: "Sleeping under the stars is nice and all, but...", prereqs: ["buildWell"], cost: 1, cooldown: nil},
      %{tree: "builder", display_name: "Build Papermill", name: "buildPapermill", type: "build", description: "Obviously a key element to your continued survival.", prereqs: ["buildTent"], cost: 1, cooldown: nil},
      %{tree: "builder", display_name: "Build Stone Mine", name: "buildStoneMine", type: "build", description: "Pull stones from the very earth!", prereqs: ["buildPapermill"], cost: 1, cooldown: nil},
      %{tree: "builder", display_name: "Build Oven", name: "buildOven", type: "build", description: "Time to stop cooking your food like hobo.", prereqs: ["buildStoneMine"], cost: 1, cooldown: nil},
      %{tree: "builder", display_name: "Build Beacon", name: "buildBeacon", type: "build", description: "Lead others to your location.", prereqs: ["buildOven"], cost: 1, cooldown: nil},
      %{tree: "builder", display_name: "Build Gold Mine", name: "buildGoldMine", type: "build", description: "Nothing to spend it on, but it still would be nice to have.", prereqs: ["buildBeacon"], cost: 1, cooldown: nil},
      
      %{tree: "gatherer", display_name: "Gather Cloth", name: "gatherCloth", type: "passive", description: "You think you can fashion cloth from the wood fibers if you chop the trees juuuust right.", prereqs: [], cost: 1, cooldown: nil, effect_value: 2.2},
      %{tree: "gatherer", display_name: "Gather Rope", name: "gatherRope", type: "passive", description: "Logic dictates that chopping even more carefully should allow you to produce rope.", prereqs: ["gatherCloth"], cost: 1, cooldown: nil, effect_value: 1.9},
      %{tree: "gatherer", display_name: "Gather Magic", name: "gatherMagic", type: "passive", description: "Somehow chop trees in a way that allows you pull magic out of them. I don't know. You come up with some flavor text.", prereqs: ["gatherRope"], cost: 1, cooldown: nil, effect_value: 1.6},
      %{tree: "gatherer", display_name: "Gather Gems", name: "gatherGems", type: "passive", description: "Has someone been hiding gems in these trees this whole time?!", prereqs: ["gatherMagic"], cost: 1, cooldown: nil, effect_value: 1.3},
      %{tree: "gatherer", display_name: "Chop Fast", name: "chopFast1", type: "passive", description: "Increase chop speed by swinging the axe faster.", prereqs: ["gatherCloth"], cost: 1, cooldown: nil},
      %{tree: "gatherer", display_name: "Chop Faster", name: "chopFast2", type: "passive", description: "Did you know swinging the axe EVEN FASTER would make you chop EVEN FASTER?", prereqs: ["gatherRope", "chopFast1"], cost: 1, cooldown: nil},
      %{tree: "gatherer", display_name: "Chop Fastest", name: "chopFast3", type: "passive", description: "Become one with the axe. Chop like the wind.", prereqs: ["gatherMagic", "chopFast2"], cost: 1, cooldown: nil},
      %{tree: "gatherer", display_name: "Chop-Dash", name: "chopDash1", type: "active", description: "You know, it might be faster to just not stop to swing the axe.", prereqs: ["gatherGems", "chopFast3"], cost: 1, cooldown: 25.0, effect_value: 200.0},
      %{tree: "gatherer", display_name: "Adv. Chop-Dash", name: "chopDash2", type: "active", description: "Yes, totally! Swinging is for chumps! Let's just get better at this chop-dash thing!", prereqs: ["chopDash1"], cost: 1, cooldown: 12.0, effect_value: 300.0},
      
      %{tree: "leader", display_name: "Emote", name: "emote", type: "active", description: "Express yourself!", prereqs: [], cost: 1, cooldown: nil},
      %{tree: "leader", display_name: "Emote More", name: "emoteMore", type: "active", description: "EXPRESS HARDER DAMMIT", prereqs: ["emote"], cost: 1, cooldown: 1.0},
      %{tree: "leader", display_name: "Track Buildings", name: "trackBuilding", type: "passive", description: "If you put your ear to the ground, you can hear the hoofbeats of nearby buildings.", prereqs: [], cost: 1, cooldown: 0.5},
      %{tree: "leader", display_name: "Track Lumberjacks", name: "trackPlayer", type: "passive", description: "Your keen awareness of lumberjack musk alerts you to when they are near.", prereqs: ["trackBuilding"], cost: 1, cooldown: nil},
      %{tree: "leader", display_name: "Boost Walk", name: "buffWalk", type: "passive_aura", description: "Inspire others to walk more briskly.", prereqs: ["emote"], cost: 1, cooldown: nil, effect_value: 1.25},
      %{tree: "leader", display_name: "Boost Chop", name: "buffChop", type: "passive_aura", description: "Your instructions on how to chop properly increases nearby lumberjack gathering ability and totally doesn't make them think you act like a know it all.", prereqs: ["buffWalk", "emoteMore"], cost: 1, cooldown: nil, effect_value: 1.25},
      %{tree: "leader", display_name: "Boost Build", name: "buffBuild", type: "passive_aura", description: "Lower the cost for nearby lumberjacks to build things by becoming the person in the group effort that always says they are 'supervising'.", prereqs: ["trackBuilding", "emoteMore"], cost: 1, cooldown: nil, effect_value: 0.75}
    ]
    |> Enum.map(fn(row) ->
      row
      |> Map.put(:inserted_at, DateTime.utc_now)
      |> Map.put(:updated_at, DateTime.utc_now)
      end)
    Sawver.Repo.insert_all(Sawver.SkillBook, initial_books)
  end

  def get_skill_list_for_player() do
    Sawver.Repo.all(Sawver.SkillBook)
    |> Enum.map(fn(sb) -> Map.take(sb, [:tree, :display_name, :name, :description, :prereqs, :cost, :cooldown, :effect_value]) end)
  end
end
