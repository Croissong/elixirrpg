defmodule ExPG.Combat do
  alias ExPG.{Character}
  require Logger
  
  defmodule Stats do 
    defstruct [:damage, :health]
    def new(damage \\10, health  \\30) do
      %Stats{damage: damage, health: health}
    end
  end

  def attack(attacker, defender) do
    attacker_cs = Character.get(attacker).c_stats
    defender_cs = Character.get(defender).c_stats
    def_health = defender_cs.health - attacker_cs.damage
    Logger.info("#{attacker.name} attacked #{defender.name} for #{attacker.damage}")
    defender = update_in(defender.combat_stats.health, def_health)
    Character.update(defender)
  end
end
