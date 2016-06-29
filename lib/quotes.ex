defmodule Expg.Quotes do
  alias RethinkDB.Query, as: Q
  alias Expg.{DB}
  require Logger

  def init do
    Q.table_create("quotes") |> DB.run
  end
  
  def add(quot) do
    IO.puts "asd"
    IO.inspect quot
    %{data: data} = Q.table("quotes") |> Q.insert(quot) |> DB.run
    %{"errors" => 0} = data 
    Logger.info("Quote #{inspect quot} added")
    {:ok, quot}
  end
end
