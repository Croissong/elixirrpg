defmodule MyRouter do 
  use Plug.Router
  import DBTest 
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  
  post "/receiveAward" do 
    DBTest.receiveAward(conn.params["type"], conn.params["amount"])
    totalPoints = DBTest.getTotalPoints
    send_resp(conn, 200, "#{totalPoints}") 
  end

  def start do
    Plug.Adapters.Cowboy.http MyRouter, []
  end
end

