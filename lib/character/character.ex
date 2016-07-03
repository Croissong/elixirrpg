defmodule Expg.Character do
  require Logger
  alias RethinkDB.Query, as: Q
  alias Expg.{DB, Combat, Characters}
  alias __MODULE__.Stats
  alias Maptu
  
  defstruct [:name, :stats, :id, :combatStats]

  def as_struct(char) do 
    Maptu.struct!(Expg.Character, char) 
    |> Map.update!(:combatStats, &Maptu.struct!(Expg.Combat.Stats, &1))
    |> Map.update!(:stats, &Maptu.struct!(Stats, &1))
    |> Map.update!(:name, &String.to_atom(&1)) 
  end

  def from_struct(char) do
    char = Map.from_struct(char)
    char = [:stats, :combatStats]
    |> Enum.reduce(char, fn (key, acc) -> Map.put(acc, key, Map.from_struct(acc[key])) end) 
    char
  end
  
  def new(name, stats \\Stats.new, c_stats \\Combat.Stats.new) do
    %Expg.Character{name: name, stats: stats, combatStats: c_stats}
  end

  def init(char) do
    char_map = char |> Map.delete(:id) |> from_struct
    query = Q.table("characters") |> Q.insert(char_map) |> DB.run 
    with %{"inserted"=> 1, "generated_keys"=> [id]} <-  query.data, 
    {:ok, char} <- Map.put(char, :id, id) |> Characters.init_char_from_struct,
      Logger.info("New character #{inspect char}"),
      do: char 
  end
  
  def new_and_init(name, stats \\Stats.new, c_stats \\Combat.Stats.new) do 
    new(name, stats, c_stats) |> init
  end
  
  def start_link(char) do 
    Agent.start_link(fn -> char end, name: char.name) 
  end
  

  def update(%{name: name} = newChar) do 
    with {:ok, id} <- Agent.get_and_update(name, &({{:ok, &1.id}, Map.merge(&1, newChar)})),
         0 <- Q.table("characters") |> Q.get(id)
         |> Q.update(from_struct(newChar)) |> DB.run |> Map.get(:data) |> Map.get("errors"),
      do: {:ok, newChar}
  end

  def get(name) do
    Agent.get(name, fn char -> char end)
  end

  def add_reward(name, reward) do
    %{xp: xpGain, gold: goldGain} = reward
    char = get(name)
    %{stats: %{xp: xp, gold: gold, level: level}} = char
    {level, xp} = level_up(level, xp + xpGain) 
    stats = Stats.new(xp, gold + goldGain, level)
    case update(%{char | stats: stats}) do
      {:ok, _} ->
        Logger.info("#{name} reward added: #{inspect reward}, total: #{inspect stats}")
        {:ok, reward}
    end
  end

  defp level_up(level, xp) do 
    levelGain = div(xp, 30) 
    if levelGain > 0, do: Logger.info("Level up")
    {level + levelGain, xp - levelGain * 30}
  end 
end

defmodule Expg.Character.Stats do
  defstruct [:level, :xp, :gold]
  def new(level \\0, xp \\0, gold \\0) do
    %__MODULE__{level: level, xp: xp, gold: gold}
  end
end


defmodule Expg.Characters do 
  use Supervisor
  alias RethinkDB.Query, as: Q 
  alias Expg.{DB, Character} 
  require Logger
    
  def start_link(_state, opts \\ 0) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(_opts \\ [] ) do
    init_from_db
    children = [
    ]
      
    supervise(children, strategy: :one_for_one)
  end

  def init_from_db do
    query = Q.table("characters") |> DB.run
    case Map.get(query, :data) do
      %{"b" => []} -> IO.puts "No characters."
      data -> Enum.map(data, &(init_char(&1)))
    end
  end

  def init_char_from_struct(%Character{} = char) do
    case Character.start_link(char) do
      {:ok, pid} ->
        Logger.info("Initialized character #{inspect pid} #{inspect char}")
        {:ok, char}
      {:error, err} -> Logger.error("#{inspect err}")
    end
  end
  
  def init_char(char) do 
    char |> Character.as_struct |> init_char_from_struct 
  end
  
end
