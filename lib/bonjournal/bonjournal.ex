defmodule Expg.Bonjournal do
  alias Expg.{DB, Character, Quests} 
  alias Timex.Time
  alias RethinkDB.Query, as: Q 
  require Logger
  
  defmodule Entry do
    defstruct [:time, :entry, :character]
  end

  def addEntry(entry, char \\:Skender) do
    entry = Map.from_struct(entry) |> Map.put(:time, Time.now(:seconds)) |> Map.put(:character, char)
    query = Q.table("bonjournal") |> Q.insert(entry) |> DB.run |> Map.get(:data)
    case query["errors"] do
      0 ->
        reward = Quests.calc_reward()
        Character.add_reward(char, reward)
        words = entry.entry |> String.split |> length 
        Logger.info("Entry added << #{String.slice(entry.entry, 21..31)}"
          <> "... #{String.slice(entry.entry, -15..-1)} >>")
        {:ok, reward, words}
      :else -> Logger.error("#{inspect query}")
    end
  end

  def getRecentEntries(count, char \\:Skender) do
    Q.table("bonjournal")
    |> Q.filter(%{character: char})
    |> Q.order_by(Q.desc(:time)) |> Q.limit(count) |> DB.run |> Map.get(:data) 
  end
end

