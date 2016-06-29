defmodule Expg.Combat do
  alias Expg.{Character}
  require Logger

  def attack(attacker, defender) do
    attacker_cs = Character.get(attacker).c_stats
    defender_cs = Character.get(defender).c_stats
    def_health = defender_cs.health - attacker_cs.damage
    Logger.info("#{attacker.name} attacked #{defender.name} for #{attacker.damage}")
    defender = update_in(defender.combat_stats.health, def_health)
    Character.update(defender)
  end

end

defmodule Expg.Combat.Stats do 
  defstruct [:damage, :health]
  def new(damage \\10, health  \\30) do
    %__MODULE__{damage: damage, health: health}
  end
end
