defmodule Character do

  alias Character.Registry, as: Reg
  
  defstruct [:name, :stats] 

  def initRegistry() do
    Reg.start_link
  end
  
  def new(stats, name) do
    c = %Character{name: name, stats: stats}
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
  defstruct [:level, :xp, :combat_stats, :gold]
  def make(combat_stats, level \\0, xp \\0, gold \\0) do
    %Character.Stats{level: level, xp: xp, combat_stats: combat_stats}
  end
end



