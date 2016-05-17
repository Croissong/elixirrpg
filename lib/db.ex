defmodule DB do
  use RethinkDB.Connection
end

defmodule DBSupervisor do 
  use Supervisor
  alias Porcelain

  def start_link do 
  Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do 
  proc = Porcelain.spawn("rethinkdb", [], [in: "", out: {:send, self()}])
  IO.inspect proc
  [ worker(DB, [[host: "localhost", port: 28015, db: to_string(Mix.env)]])
  ] |> supervise(strategy: :one_for_one)
  end
end

defmodule DBTest do
  alias RethinkDB.Query, as: Q 
  import RethinkDB.Lambda
  alias DB
  
  def new do
    Q.table_drop("quests") |> DB.run
    Q.table_create("quests") |> DB.run
  end
  
  def addQuest(quest) do
    %{data: data} = Q.table("quests") |> Q.insert(Map.from_struct(quest)) |> DB.run
    %{"errors" => 0, "generated_keys" => [key]} = data
    {:ok, key}
  end

  def getTotalPoints() do
    Q.table("quests") |> Q.filter(%{"state" => "done"}) |> Q.map(lambda fn (quest) ->
      quest[:amount] end) |> DB.run |> Map.get(:data) |> Enum.reduce(0, fn(x, acc) -> acc + x end)
  end

  def getQuests(state) do
    Q.table("quests") |> Q.filter(%{"state" => state}) |> DB.run |> Map.get(:data)
  end
end

defmodule Quest do
  @derive [Poison.Encoder]
  defstruct [:title, :type, :amount, :state, :content]
end
