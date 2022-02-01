defmodule HelloClusterWorker.Starter do
  use GenServer

  require Logger

  @spec start_link(term) :: GenServer.on_start()
  def start_link(arg) do
    case GenServer.start_link(__MODULE__, arg, name: via_tuple()) do
      {:ok, pid} ->
        Logger.debug("Started at #{inspect(pid)} on #{node(pid)}")

        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.debug("Already started at #{inspect(pid)} on #{node(pid)}, ignoring")

        :ignore
    end
  end

  @impl GenServer
  def init(_arg) do
    Process.flag(:trap_exit, true)

    {:ok, []}
  end

  @impl GenServer
  def handle_call({:start_worker, child_spec}, _from, state) do
    reply = Horde.DynamicSupervisor.start_child(HelloClusterWorker.DynamicSupervisor, child_spec)

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_info({:EXIT, _from, {:name_conflict, name, registry, pid}}, state) do
    Logger.debug("Shutting down #{inspect(name)} because of a name conflict with #{inspect(pid)} via #{inspect(registry)}")

    {:stop, :normal, state}
  end

  defp via_tuple, do: {:via, Horde.Registry, {HelloCluster.Registry, __MODULE__}}
end
