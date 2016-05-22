defmodule Bonjournal do
  alias DBTest
  alias Timex.Time
  alias RethinkDB.Query, as: Q
  alias Character
  require Logger
  
  defmodule Entry do
    defstruct [:time, :entry, :character]
  end

  def addEntry(entry, char \\:Skender) do
    entry = Map.from_struct(entry) |> Map.put(:time, Time.now(:seconds)) |> Map.put(:character, char)
    query = Q.table("bonjournal") |> Q.insert(entry) |> DB.run |> Map.get(:data)
    case query["errors"] do
      0 ->
        reward = DBTest.calcReward()
        Character.addReward(char, reward)
        lines = entry.entry |> String.split("\n") |> length
        Logger.info("Entry added #{String.slice(entry.entry, 0, 20)}")
        {:ok, reward, lines}
      :else -> Logger.error("#{inspect query}")
    end
  end
end

