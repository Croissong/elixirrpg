defmodule ExPG.Character do
  require Logger
  alias RethinkDB.Query, as: Q
  alias ExPG.{DB, Combat, Characters}
  alias Maptu
  
  defstruct [:name, :stats, :id, :combatStats]
  
  defmodule Stats do
    defstruct [:level, :xp, :gold]
    def new(level \\0, xp \\0, gold \\0) do
      %Stats{level: level, xp: xp, gold: gold}
    end
  end

  def as_struct(char) do 
    Maptu.struct!(ExPG.Character, char) |>
      Map.update!(:combatStats, &Maptu.struct!(Combat.Stats, &1)) |> Map.update!(:stats, &Maptu.struct!(Stats, &1)) |> Map.update!(:name, &String.to_atom(&1)) 
  end

  def from_struct(char) do
    char = Map.from_struct(char)
    char = [:stats, :combatStats]
    |> Enum.reduce(char, fn (key, acc) -> Map.put(acc, key, Map.from_struct(acc[key])) end) 
    char
  end
                    
  def new(name, stats \\Stats.new, c_stats \\Combat.Stats.new) do
    %ExPG.Character{name: name, stats: stats, combatStats: c_stats}
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
    stats = %Stats{xp: xp, gold: gold + goldGain, level: level}
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
                    
defmodule ExPG.Characters do 
  alias RethinkDB.Query, as: Q 
  alias ExPG.{DB, Character} 
  require Logger

  def init_from_db do
    Q.table("characters") |> DB.run |> Map.get(:data) |> Enum.map(&(init_char(&1)))
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
