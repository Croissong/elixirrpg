defmodule Elixirpg do
	defmodule Character do
		defstruct name: "", stats: nil
		def make(stats, name) do
			%Character{name: name, stats: stats}
		end
	end

	defmodule CombatStats do
		defstruct damage: 0, health: 0
		def make(damage, health) do
			%CombatStats{damage: damage, health: health}
		end
	end

	defmodule Stats do
		defstruct level: 0, xp: 0, combat_stats: nil
		def make(combat_stats, level \\ 0, xp \\ 0) do
			%Stats{level: level, xp: xp, combat_stats: combat_stats}
		end
	end

	skender = CombatStats.make(10, 20) |> Stats.make |> Character.make("Skender")
	soehnke = CombatStats.make(5, 30) |> Stats.make(1) |> Character.make("Soehnke")

	defmodule Combat do
		def attack(attacker, defender) do
			def_stats = defender.stats.combat_stats
			att_stats = attacker.stats.combat_stats
			def_health = def_stats.health - att_stats.damage
			defstats = %{def_stats | health: def_health}
			%{defender | stats: %{defender.stats | combat_stats: defstats}}
		end

	end

	soehnke = Combat.attack(skender, soehnke)


	defmodule Weapon do
		defstruct (name: "",
							 min_dmg: 0.0,
							 max_dmg: 0.0,
							 speed: 0.0,
		)
	end
