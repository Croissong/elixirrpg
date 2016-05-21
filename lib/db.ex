defmodule DB do 
  alias RethinkDB.Connection, as: Conn
  alias RethinDB.Query, as: Q
  alias Porcelain.Process, as: Proc

  def new do
    Q.db_drop(Mix.env) |> DB.run
    Q.db_create(Mix.env) |> DB.run
  end
  
  def start_link(opts) do 
  {:ok, pid} = Task.start_link(fn -> print_output end)
  IO.puts ("asddas")
  %Proc{pid: pid} = Porcelain.spawn("rethinkdb", [], out: {:send, pid})
  Conn.start_link(opts)
  end

  def print_output do
    receive do
      {_, :data, :out, data} -> 
        print_output
    end
  end
end

defmodule DBSupervisor do 
  use Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def init([]) do 
  children = [
      worker(DB, [[host: "localhost", port: 28015, db: to_string(Mix.env)]])
    ]
  
  supervise(children, strategy: :one_for_one)
  end
end

defmodule DBTest do
  alias RethinkDB.Query, as: Q 
  import RethinkDB.Lambda
  alias DB
  alias Timex.Time
  require Logger
  
  def new do 
  Q.table_drop("quests") |> DB.run
  Q.table_create("quests") |> DB.run
  end
  
  def addQuest(quest, char \\:Skender) do
    quest = Map.from_struct(quest) |> Map.put(:acceptTime, Time.now(:secs)) |> Map.put(:character, char)
    %{data: data} = Q.table("quests") |> Q.insert(quest) |> DB.run
    %{"errors" => 0, "generated_keys" => [key]} = data
    Logger.info("Quest #{inspect quest} added")
    {:ok, key}
  end

  def getQuest(id) do
  end

  def updateQuest(id, updates) do
    updateState(updates)
    changes = Query.table("quests")
    |> Query.get(id)
    |> Query.update(updates, %{return_changes: true}) |> DB.run |> get_in([:data, "changes"])
    Logger.info("Quest #{id} updated: #{changes}")
    {:ok, changes}
  end

  def updateState(updates) do
    case updates.state do
      "done" -> completeQuest(updates)
    end
  end

  def completeQuest(quest) do
    xp = calcXpReward(quest)
    gold = calcGoldReward(quest)
    reward = %{xp: xp, gold: gold}
    Character.addReward(quest.character, reward)
    Map.put(quest, :completeTime, Time.now(:secs)) |> Map.put(:reward, reward)
    Logger.info("Quest #{quest} completed")
  end

  def getTotalPoints() do
    Q.table("quests") |> Q.filter(%{"state" => "done"})
    |> Q.map(lambda fn (quest) -> quest[:amount] end)
    |> DB.run |> Map.get(:data) |> Enum.reduce(0, fn(x, acc) -> acc + x end)
  end

  def getQuests(state) do
    Q.table("quests") |> Q.filter(%{"state" => state}) |> DB.run |> Map.get(:data)
  end

  def calcXpReward(quest) do
    5
  end

  def calcGoldReward(quest) do
    10
  end
    
end

defmodule Quest do
  @derive [Poison.Encoder]
  defstruct [:title, :type, :amount, :state, :content, :acceptTime, :completeTime, :character]
end
