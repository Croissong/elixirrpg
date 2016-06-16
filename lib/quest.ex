defmodule ExPG.Quest do
  @derive [Poison.Encoder]
  defstruct [:title, :type, :reward, :state, :content, :acceptTime, :completeTime, :character]
end

defmodule ExPG.Quests do
  alias RethinkDB.Query, as: Q 
  alias ExPG.{DB, Character} 
  alias Timex.Time
  alias HTTPoison
  require Logger

  def add(quest, char \\:Skender) do 
    quest = Map.from_struct(quest) |> Map.put(:acceptTime, Time.now(:seconds)) |> Map.put(:character, char)
    quest =
      case quest.state do
        "done" -> complete(quest)
      end 
    %{data: data} = Q.table("quests") |> Q.insert(quest) |> DB.run
    %{"errors" => 0, "generated_keys" => [key]} = data
    quest = quest |> Map.put(:id, key)
    Logger.info("Quest #{inspect quest} added")
    {:ok, %{quest: quest}}
  end

  # def get(id) do
  # end

  def update(id, updates) do
    updates = update_state(updates)
    changes = Q.table("quests")|> Q.get(id)
    |> Q.update(updates, %{return_changes: true}) |> DB.run |> get_in([:data, "changes"])
    Logger.info("Quest #{id} updated: #{changes}")
    {:ok, changes}
  end

  def update_state(updates) do
    case updates.state do
      "done" -> complete(updates)
    end
  end

  def calc_reward() do
    xp = calc_xp(nil)
    gold = calc_gold(nil)
    %{xp: xp, gold: gold}
  end

  def complete(quest) do
    reward = calc_reward()
    Character.add_reward(quest.character, reward)
    quest = quest |> Map.put(:completeTime, Time.now(:secs)) |> Map.put(:reward, reward)
    Logger.info("Quest #{inspect quest} completed")
    HTTPoison.start
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get "http://quotes.rest/qod.json"
    %{"contents" => %{"quotes" => [%{"quote" => q}]}} = Poison.decode! body
    Logger.info(q)
    quest
  end

  def get_all(state) do
    Q.table("quests") |> Q.filter(%{"state" => state}) |> DB.run |> Map.get(:data)
  end

  def calc_xp(_) do
    5
  end

  def calc_gold(_) do
    10
  end    
end
