defmodule Expg do 
  use Application
  alias Expg.{DBSupervisor, Router, Character, Characters, DB} 

  def new do
    DB.new
    Character.new_and_init(:Skender)
    Character.new_and_init(:Enemy)
  end

  def start(_type \\[], _args \\[]) do 
    DBSupervisor.start_link
    Router.start
    Characters.init_from_db
    IO.puts "ready"
  end
end
