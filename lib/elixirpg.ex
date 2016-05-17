defmodule ElixirRpg do 
  use Application
  alias DBSupervisor
  alias MyRouter

  def start do
    start([], [])
  end
  
  def start(_type, _args) do 
  DBSupervisor.start_link
  MyRouter.start
  end
end
# require Character, as: Char
# require Combat
# require DB
# require Character.Stats, as: S
# require Combat.Stats, as: CS 
   
# {:ok, skender} = CS.make(10, 20) |> S.make |> Char.new("Skender")
# {:ok, soehnke} = CS.make(5, 30) |> S.make(1) |> Char.new("Soehnke")
# Combat.attack(skender, soehnke)
# Combat.attack(skender, soehnke)
# Char.get(soehnke).stats.combat_stats.health
