defmodule Combat do
  defmodule Stats do
	  defstruct damage: 0, health: 0
	  def make(damage, health) do
		  %Stats{damage: damage, health: health}
	  end
  end

  def attack(att_pid, def_pid) do
    defender = Character.get(def_pid)
    attacker = Character.get(att_pid)
		def_stats = defender.stats.combat_stats
		att_stats = attacker.stats.combat_stats
		def_health = def_stats.health - att_stats.damage
		defstats = %{def_stats | health: def_health}
		defender = %{defender | stats: %{defender.stats | combat_stats: defstats}}
    Character.update(def_pid, defender)
	end
end
