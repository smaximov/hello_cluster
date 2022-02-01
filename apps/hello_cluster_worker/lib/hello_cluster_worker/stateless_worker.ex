defmodule HelloClusterWorker.StatelessWorker do
  use GenServer, restart: :temporary

  @spec start_link(term) :: GenServer.on_start()
  def start_link(arg), do: GenServer.start_link(__MODULE__, arg)

  @impl GenServer
  def init(_arg), do: {:ok, []}

  @impl GenServer
  def handle_call(:greet, _from, state) do
    greeting = "Hello from #{inspect(self())} on #{node()}!"

    {:stop, :normal, greeting, state}
  end
end
