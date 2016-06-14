defmodule ExPG.Quest do
  @derive [Poison.Encoder]
  defstruct [:title, :type, :reward, :state, :content, :acceptTime, :completeTime, :character]
end

defmodule ExPG.Quests do
  alias RethinkDB.Query, as: Q 
  import RethinkDB.Lambda
  alias DB
  alias Timex.Time
  require Logger

  def add(quest, char \\:Skender) do
    quest = Map.from_struct(quest) |> Map.put(:acceptTime, Time.now(:seconds)) |> Map.put(:character, char)
    %{data: data} = Q.table("quests") |> Q.insert(quest) |> DB.run
    %{"errors" => 0, "generated_keys" => [key]} = data
    Logger.info("Quest #{inspect quest} added")
    {:ok, key}
  end

  def get(id) do
  end

  def update(id, updates) do
    update_state(updates)
    changes = Query.table("quests")
    |> Query.get(id)
    |> Query.update(updates, %{return_changes: true}) |> DB.run |> get_in([:data, "changes"])
    Logger.info("Quest #{id} updated: #{changes}")
    {:ok, changes}
  end

  def update_state(updates) do
    case updates.state do
      "done" -> complete_quest(updates)
    end
  end

  def calc_reward() do
    xp = calc_xp(nil)
    gold = calc_gold(nil)
    %{xp: xp, gold: gold}
  end

  def complete(quest) do
    reward = calc_reward()
    Character.addReward(quest.character, reward)
    Map.put(quest, :completeTime, Time.now(:secs)) |> Map.put(:reward, reward)
    Logger.info("Quest #{quest} completed")
  end

  def get_all(state) do
    Q.table("quests") |> Q.filter(%{"state" => state}) |> DB.run |> Map.get(:data)
  end

  def calc_xp(quest) do
    5
  end

  def calc_gold(quest) do
    10
  end    
end
