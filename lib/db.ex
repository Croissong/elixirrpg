defmodule DB do 
  alias RethinkDB.Connection, as: Conn
  alias RethinkDB.Query, as: Q
  alias Porcelain.Process, as: Proc
  require Logger
  
  def run(query, opts \\ []) do
    Conn.run(query, __MODULE__, opts)
  end
  
  def new do
    Q.db_drop(Mix.env) |> run
    with _ <- Q.db_create(Mix.env) |> run |> Map.get(:data) |> Map.get("dbs_created"),
         1 <- Q.table_create("quests") |> run |> Map.get(:data) |> Map.get("tables_created"),
           1 <- Q.table_create("characters") |> run |> Map.get(:data) |> Map.get("tables_created"),
           1 <- Q.table_create("bonjournal") |> run |> Map.get(:data) |> Map.get("tables_created"),
      do: Logger.info("Renewed DB")
  end
  
  def start_link(opts) do 
  {:ok, pid} = Task.start_link(fn -> print_output end)
  dir = "rethinkdb_data/" <> to_string(Mix.env) <> "/"
  %Proc{pid: pid} = Porcelain.spawn("rethinkdb", ["-d", dir], [out: {:send, pid}])
  Conn.start_link(Dict.put_new(opts, :name, __MODULE__))
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

  def addQuest(quest, char \\:Skender) do
    quest = Map.from_struct(quest) |> Map.put(:acceptTime, Time.now(:seconds)) |> Map.put(:character, char)
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

  def calcReward() do
    xp = calcXpReward(nil)
    gold = calcGoldReward(nil)
    %{xp: xp, gold: gold}
  end

  def completeQuest(quest) do
    reward = calcReward()
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
  defstruct [:title, :type, :reward, :state, :content, :acceptTime, :completeTime, :character]
end
