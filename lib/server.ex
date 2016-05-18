defmodule MyRouter do 
  use Plug.Router
  alias Plug.Conn
  alias DBTest
  alias Quest
  plug :match
  plug :dispatch

  get "/totalPoints" do
    totalPoints = DBTest.getTotalPoints
    send_resp(conn, 200, "#{totalPoints}")
  end

  get "/test" do 
    send_resp(conn, 200, "test")
  end
  
  post "/addQuest" do
    {:ok, body, conn} = Conn.read_body(conn)
    quest = Poison.decode!(body, as: %Quest{})
    case DBTest.addQuest(quest) do
      {:ok, id} ->
        resp = Poison.encode!(%{id: id})
        send_resp(conn, 200, resp)
      {:error, error} ->
        send_resp(conn, 500, error)
    end
  end

  post "/updateQuest" do
    {:ok, body, conn} = Conn.read_body(conn)
    {%{id: id}, quest} = Poison.Parser.parse!(body, keys: :atoms!) |> Map.split([:id]) 
    case DBTest.updateQuest(id, quest) do
      {:ok, changes} ->
        resp = Poison.encode!(%{changes: changes})
        send_resp(conn, 200, resp)
      {:error, error} ->
        send_resp(conn, 500, error)
    end
  end

  post "/getQuests" do
    {:ok, body, conn} = Conn.read_body(conn)
    with %{"state" => state} <- Poison.Parser.parse!(body),
         quests = DBTest.getQuests(state) |> Poison.encode!,
      do: send_resp(conn, 200, quests)
  end
  def start do
    Plug.Adapters.Cowboy.http MyRouter, []
  end
end

