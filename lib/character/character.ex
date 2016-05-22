defmodule Character do
  require Logger
  alias RethinkDB.Query, as: Q
  alias DB
  
  defstruct [:name, :stats, :id]
  
  defmodule Stats do
    defstruct [:level, :xp, :gold]
    def new(level \\0, xp \\0, gold \\0) do
      %Stats{level: level, xp: xp, gold: gold}
    end
  end
  
  def new(name, stats \\ %{}) do 
  char = %{name: name, stats: stats} 
  query = Q.table("characters") |> Q.insert(char) |> DB.run
  with %{"inserted"=> 1, "generated_keys"=> [id]} <-  query.data,
       char = Map.put(char, :id, id) |> update_in([:stats], &Map.merge(Stats.new, &1)),
       {:ok, char} <- struct(Character, char) |> Characters.initChar,
         Logger.info("New character #{inspect char}"),
    do: char 
  end
  
  def start_link(char) do 
  Agent.start_link(fn -> char end, name: char.name) 
  end
  
  def update(name, newChar) do 
  with {:ok, id} <- Agent.get_and_update(name, &({{:ok, &1.id}, Map.merge(&1, newChar)})),
       0 <- Q.table("characters") |> Q.get(id)
       |> Q.update(newChar) |> DB.run |> Map.get(:data) |> Map.get("errors"),
      do: {:ok, newChar}      
  end

  def get(name) do
    Agent.get(name, fn char -> char end)
  end

  def addReward(name, reward) do
    %{xp: xpGain, gold: goldGain} = reward
    %{stats: %{xp: xp, gold: gold, level: level}} = get(name)
    {level, xp} = levelUp(level, xp + xpGain)
    reward = %{xp: xp, gold: gold + goldGain, level: level}
    case update(name, %{stats: reward}) do
      {:ok, _} ->
        Logger.info("#{name} reward added: #{inspect reward}")
        {:ok, reward}
    end
  end

  defp levelUp(level, xp) do
    levelGain = div(xp, 30)
    if levelGain > 0, do: Logger.info("Level up")
    {level + levelGain, xp - levelGain * 30}
  end
end
  
defmodule Characters do
  import RethinkDB.Lambda
  alias RethinkDB.Query, as: Q 
  alias DB
  alias Character
  require Logger

  def init do
    Q.table("characters") |> DB.run |> Map.get(:data) |> Enum.map(&(initChar(&1)))
  end

  def initChar(char) do
    case Map.merge(%Character{}, char) |> Character.start_link do
      {:ok, char} ->
        Logger.info("Initialized character #{inspect char}")
        {:ok, char}
      {:error, err} -> Logger.error("#{inspect err}")
    end
  end
end
