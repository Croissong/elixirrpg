defmodule Character do
  require Logger
  
  defstruct [:name, :stats]
  defmodule Stats do
    defstruct [:level, :xp, :gold]
    def new(level \\0, xp \\0, gold \\0) do
      %Stats{level: level, xp: xp, gold: gold}
    end
  end
  
  def new(name, stats \\ %{}) do
    char = %Character{name: name, stats: Map.merge(Stats.new, stats)}
    Logger.info("New character #{inspect char}")
    char
  end
  
  def start_link(char) do
    IO.inspect char
    Agent.start_link(fn -> char end, name: char.name)
    char
  end
  
  def update(name, newChar) do
    Agent.get_and_update(name,
      fn char ->  Map.merge(char, newChar) end
    )
  end

  def get(name) do
    Agent.get(name, fn char -> char end)
  end

  def addReward(name, reward) do
    %{xp: xpGain, gold: goldGain} = reward
    %{xp: xp, gold: gold, level: level} = get(name)
    {level, xp} = levelUp(level, xp + xpGain)
    reward = %{xp: xp, gold: gold + goldGain, level: level}
    Logger.info("#{name} reward added: #{inspect reward}")
    Agent.update(name, reward)
  end

  def levelUp(level, xp) do
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
  
  def new do
    Q.table_drop("characters") |> DB.run
    Q.table_create("characters") |> DB.run
  end

  def init do
    Q.table("characters") |> DB.run |> Map.get(:data) |> Enum.map(&(initChar(&1)))
  end

  def initChar(char) do
    case Map.merge(%Character{}, char) |> Character.start_link do
      {:ok, char} -> Logger.info("Initialized character #{inspect char}")
    end
  end
end
