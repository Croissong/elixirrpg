defmodule ExPG.Character do
  require Logger
  alias RethinkDB.Query, as: Q
  alias ExPG.{DB, Combat}
  
  defstruct [:name, :stats, :id, :combat_stats]
  
  defmodule Stats do
    defstruct [:level, :xp, :gold]
    def new(level \\0, xp \\0, gold \\0) do
      %Stats{level: level, xp: xp, gold: gold}
    end
  end

  def as_struct(char) do
    new(char.name) |> Map.merge(char)
  end

  def from_struct(char) do
    for key <- [[:stats], [:cs]] do
      Map.from_struct(char) |> get_and_update_in(key, &Map.from_struct(&1))
    end
  end

  def new(name, stats \\Stats.new, c_stats \\Combat.Stats.new) do
    %Character{name: name, stats: stats, combat_stats: combat_stats}
  end

  def init(char) do
    query = Q.table("characters") |> Q.insert(from_struct(char)) |> DB.run
    with %{"inserted"=> 1, "generated_keys"=> [id]} <-  query.data, 
    {:ok, char} <- Map.put(char, :id, id) |> Characters.initChar,
      Logger.info("New character #{inspect char}"),
      do: char 
  end
  
  def new_and_init(name, stats \\Stats.new, c_stats \\Combat.Stats.new) do 
  new(name, stats, c_stats) |> init
  end
  
  def start_link(char) do
    IO.inspect char
    IO.inspect char.name
    Agent.start_link(fn -> char end, name: char.name) 
  end
  

  def update(%{name: name} = newChar) do 
  with {:ok, id} <- Agent.get_and_update(name, &({{:ok, &1.id}, Map.merge(&1, newChar)})),
       0 <- Q.table("characters") |> Q.get(id)
       |> Q.update(newChar) |> DB.run |> Map.get(:data) |> Map.get("errors"),
      do: {:ok, newChar}
  end

  def get(name) do
    Agent.get(name, fn char -> char end)
  end

  def add_reward(name, reward) do
    %{xp: xpGain, gold: goldGain} = reward
    char = get(name) |> IO.inspect
    %{stats: %{xp: xp, gold: gold, level: level}} = char
    {level, xp} = levelUp(level, xp + xpGain)
    reward = %{xp: xp, gold: gold + goldGain, level: level}
    case update(name, %{stats: reward}) do
      {:ok, _} ->
        Logger.info("#{name} reward added: #{inspect reward}")
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
  import RethinkDB.Lambda
  alias RethinkDB.Query, as: Q 
  alias ExPG.{DB, Character} 
  require Logger

  def init_from_db do
    Q.table("characters") |> DB.run |> Map.get(:data) |> Enum.mapEnum.map(&(init_char(&1)))
  end

 
  def init_char(char) do
    Character.as_struct(char) |> initc
  end
  
  def init_char(%Character{} = char) do
    case Character.start_link(char) do
      {:ok, char} ->
        Logger.info("Initialized character #{inspect char}")
        {:ok, char}
      {:error, err} -> Logger.error("#{inspect err}")
    end
  end
end
