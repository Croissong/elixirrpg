defmodule Mix.Tasks.Expg.Prod do
  require Logger
  use Mix.Task
  alias Expg
  
  def run(_args) do
    Mix.env :prod
    Logger.info("Starting Expg in production mode.")
    Expg.start
  end
end

defmodule Mix.Tasks.Expg.Dev do
  require Logger
  use Mix.Task
  alias Expg
  
  def run(_args) do 
    Mix.env :dev
    Code.ensure_compiled(Porcelain)
    IO.inspect Application.fetch_env(:porcelain, :driver_internal)
    IO.inspect IO.inspect Application.get_all_env(:porcelain)
    Logger.info("Starting Expg in dev mode.")
    Expg.start
  end
end
