defmodule Expg.Supervisor do
  use Supervisor
  alias Expg.{DBSupervisor, Router, Characters}

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(DBSupervisor, [DBSupervisor]),
      worker(Characters, [Characters])
    ]
    Router.start 
    supervise(children, strategy: :one_for_one)
  end
end
