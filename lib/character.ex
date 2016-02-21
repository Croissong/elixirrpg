defmodule Character do

  defmodule Stats do
		defstruct level: 0, xp: 0, combat_stats: nil
		def make(combat_stats, level \\ 0, xp \\ 0) do
			%Stats{level: level, xp: xp, combat_stats: combat_stats}
		end
	end
  
	defstruct(
    name: "",
    stats: nil
  )
  
	def new(stats, name) do
		c = %Character{name: name, stats: stats}
    Agent.start_link(fn -> c end)
	end

  def update(pid, char) do
    Agent.get_and_update(pid,
      fn _c ->  {char, char} end
    )
  end

  def get(pid) do
    Agent.get(pid, fn char -> char end)
  end
end


