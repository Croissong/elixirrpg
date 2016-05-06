defmodule Character.Registry do
  use GenServer
  alias Character.Registry.Server, as: Server
  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link() do
    GenServer.start_link(Server, :ok, [])
  end

  @doc """
  Looks up the character pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a character associated to the given `name` in `server`.
  """
  def create(server, character) do
    GenServer.cast(server, {:create, character})
  end
end

defmodule Character.Registry.Server do

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  def handle_call({:create, character}, names) do
    name = character.name
    if Map.has_key?(names, name) do
      {:error, :exists}
    else
      {:ok, Map.put(names, name, character)}
    end
  end
end
