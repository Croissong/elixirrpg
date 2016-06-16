defmodule ExPG.DB do 
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
    %Proc{pid: _} = Porcelain.spawn("rethinkdb", ["-d", dir], [out: {:send, pid}])
    :timer.sleep(2000)
    Conn.start_link(Dict.put_new(opts, :name, __MODULE__))
  end

  def print_output do
    receive do
      {_, :data, :out, data} ->
        IO.inspect data
        print_output
    end
  end
end

defmodule ExPG.DBSupervisor do 
  use Supervisor
  
  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def init([]) do 
    children = [
      worker(ExPG.DB, [[host: "localhost", port: 28015, db: to_string(Mix.env)]])
    ]
  
    supervise(children, strategy: :one_for_one)
  end
end
