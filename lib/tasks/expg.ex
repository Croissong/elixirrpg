defmodule Mix.Tasks.Expg.Prod do
  require Logger
  use Mix.Task
  alias Expg
  
  def run(_args) do
    Mix.env :prod
    Logger.info("Starting Expg in production mode.")
    Mix.Task.run "run"
  end
end

defmodule Mix.Tasks.Expg.Dev do
  require Logger
  use Mix.Task
  alias Expg
  
  def run(_args) do 
    Mix.env :dev
    Logger.info("Starting Expg in dev mode.")
    Mix.Task.run "run"
  end
end

defmodule Mix.Tasks.Expg.New do
  use Mix.Task
  alias Expg.{Character, DB}
  
  def run(_args) do
    DB.new
    Character.new_and_init(:Skender)
    Character.new_and_init(:Enemy)
  end
end
