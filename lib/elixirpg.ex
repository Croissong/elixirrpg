defmodule ExPG do 
  use Application
  alias ExPG.{DBSupervisor, Router, Character, DB} 

  def new do
    DB.new
    Character.new_and_init(:Skender)
    Character.new_and_init(:Enemy)
  end

  def start(_type \\[], _args \\[]) do 
  DBSupervisor.start_link
  Router.start
  IO.puts "ready"
  end
end
