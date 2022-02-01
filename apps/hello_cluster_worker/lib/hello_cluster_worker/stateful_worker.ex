defmodule HelloClusterWorker.StatefulWorker do
  use GenServer, restart: :transient

  require Logger

  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(name), do: GenServer.start_link(__MODULE__, name, name: via_tuple(name))

  @impl GenServer
  def init(name) do
    state = %{name: name, count: 1, timer: schedule_timeout()}

    {:ok, state}
  end

  @timeout :timer.seconds(10)

  @impl GenServer
  def handle_call(:greet, _from, %{name: name, count: count, timer: timer} = state) do
    Process.cancel_timer(timer)

    greeting = """
      Hello to #{name} from #{inspect(self())} on #{node()}!

      This server was called #{count} time(s) and will shut down after #{@timeout}ms of inactivity.
    """

    state = %{state | count: count + 1, timer: schedule_timeout()}

    {:reply, greeting, state}
  end

  @impl GenServer
  def handle_info(:timeout, %{name: name} = state) do
    Logger.debug("#{inspect(self())} (#{name}) timed out while waiting for a message, shutting down...")

    {:stop, :normal, state}
  end

  defp schedule_timeout, do: Process.send_after(self(), :timeout, @timeout)

  defp via_tuple(name), do: {:via, Horde.Registry, {HelloCluster.Registry, {__MODULE__, name}}}
end
