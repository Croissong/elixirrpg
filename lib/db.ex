defmodule DB do
  use RethinkDB.Connection
end

defmodule DBSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    [ worker(DB, [[host: "localhost", port: 28015]])
    ] |> supervise(strategy: :one_for_one)
  end
end

defmodule DBTest do
  alias RethinkDB.Query, as: Q
  require RethinkDB.Lambda 
  import RethinkDB.Lambda
  import DB
  
  def new do
    Q.table_drop("points") |>
      Q.table_create("points") |>
      DB.run
  end
  
  def receiveAward(type, amount) do
    Q.table("points") |> Q.insert(%{type: type, amount: amount}) |> DB.run
  end

  def getTotalPoints() do
    Q.table("points") |> Q.map(lambda fn (award) ->
      award[:amount] end) |> DB.run |> Map.get(:data) |> Enum.reduce(0, fn(x, acc) -> acc + x end)
  end
end

