defmodule Character do
  alias Character.Stats
  defstruct [:name, :stats] 

  def init
  
  def start_link(char) do 
  Agent.start_link(fn => char end, name: char.name)
  end

  def save(char, registry) do
    Reg.create(registry, char)
  end
  
  def update(char, registry) do
    Agent.get_and_update(registry,
      fn _c ->  {char, char} end
    )
  end

  def get(pid) do
    Agent.get(pid, fn char -> char end)
  end
end

defmodule Character.Stats do
  defstruct [:level, :xp, :gold]
  def make(level \\0, xp \\0, gold \\0) do
    %Character.Stats{level: level, xp: xp, combat_stats: combat_stats}
  end
end

defmodule Characters do
  import RethinkDB.Lambda
  alias RethinkDB.Query, as: Q 
  alias DB
  alias Character
  
  def new do
    Q.table_drop("characters") |> DB.run
    Q.table_create("characters") |> DB.run
  end

  def init do
    Q.table("characters") |> DB.run |> Map.get(:data) |> Enum.map(&(createCharacter(&1)))
  end

  def createCharacter(char) do
    struct(Character, char) |> Character.start_link
  end
end
