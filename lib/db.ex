defmodule DB do 
  import Porcelain 
  alias RethinkDB.Connection, as: Conn
  
  def start_link(opts) do 
  {:ok, pid} = Task.start_link(fn -> print_output end)
  Porcelain.spawn("rethinkdb", [], [in: "", out: {:send, pid}])
  Conn.start_link(opts)
  end

  def print_output do
    receive do
      {_, :data, :out, data} ->
        IO.inspect(data)
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
  
  def new do
    Q.table_drop("quests") |> DB.run
    Q.table_create("quests") |> DB.run
  end
  
  def addQuest(quest) do
    quest = Map.from_struct(quest) |> Map.put(quest, :acceptTime, Time.now(:secs))
    %{data: data} = Q.table("quests") |> Q.insert(quest) |> DB.run
    %{"errors" => 0, "generated_keys" => [key]} = data
    {:ok, key}
  end

  def getQuest(id) do
  end

  def updateQuest(id, updates) do
    quest = with %{state: state} <- updates,
      do: Map.merge(updates, updateState(state))
    changes = Query.table("quests")
    |> Query.get(id)
    |> Query.update(updates, %{return_changes: true}) |> DB.run |> get_in([:data, "changes"])
    {:ok, changes}
  end

  def updateState(quest) do
    case quest.state do
      "done" -> completeQuest(quest)
      "todo" -> Ma
    end
  end

  def completeQuest(quest) do
    xp = calcXpReward(quest)
    gold = calcGoldReward(quest)
    reward = %{xp: xp, gold: gold}
    Character.addReward(reward)
    Map.put(quest, :completeTime, Time.now(:secs)) |> Map.put(:reward, reward)
  end

  def getTotalPoints() do
    Q.table("quests") |> Q.filter(%{"state" => "done"}) |> Q.map(lambda fn (quest) ->
      quest[:amount] end) |> DB.run |> Map.get(:data) |> Enum.reduce(0, fn(x, acc) -> acc + x end)
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
  defstruct [:title, :type, :amount, :state, :content, :acceptTime, :completeTime]
end
