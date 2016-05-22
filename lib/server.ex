defmodule MyRouter do 
  use Plug.Router
  alias Plug.Conn
  alias DBTest
  alias Quest
  alias Bonjournal
  alias Character
  plug :match
  plug :dispatch

  post "/characterInfo" do
    {:ok, body, conn} = Conn.read_body(conn)
    %{character: char} = Poison.Parser.parse!(body, keys: :atoms!)
    case String.to_atom(char) |> Character.get do
      char ->
        resp = Poison.encode!(%{char: char})
        send_resp(conn, 200, resp)
      {:error, err} ->
        send_resp(conn, 500, err)
    end
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
      {:error, err} ->
        send_resp(conn, 500, err)
    end
  end

  post "/addBonentry" do
    {:ok, body, conn} = Conn.read_body(conn)
    entry = Poison.decode!(body, as: %Bonjournal.Entry{})
    case Bonjournal.addEntry(entry) do
      {:ok, reward, lines} ->
        resp = Poison.encode!(%{reward: reward, lines: lines})
        send_resp(conn, 200, resp)
      {:error, err} ->
        send_resp(conn, 500, err)
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

