defmodule Expg do 
  use Application 

  def start(_type \\[], _args \\[]) do 
    Expg.Supervisor.start_link
  end
end
