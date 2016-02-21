defmodule DB do
	# use RethinkDB.Connection
  require RethinkDB, as: Rethink
  require RethinkDB.Query, as Q
	require RethinkDB.Connection, as: Conn
	def new() do
		{:ok, conn} = Conn.start_link([host: "127.0.0.1", port: 28015])
    Q.table_create("character")
    |> run(conn)
	end

  def insert(table, ins) do
    Q.table(table) |> Q.insert(ins) | run()
  end
end
