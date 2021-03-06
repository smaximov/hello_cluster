defmodule HelloClusterMain do
  @spec greet() :: String.t()
  def greet do
    # We add randomness to child spec of `StatelessWorker` because otherwise
    # it would be started on the same node every time (`Horde.DynamicSupervisor`
    # by default used a hash ring strategy with child spec as a hash key to
    # choose a node for a process):
    {:ok, pid} = start_worker(HelloClusterWorker.StatelessWorker, :rand.uniform())

    GenServer.call(pid, :greet)
  end

  @spec greet(String.t()) :: String.t()
  def greet(name) do
    pid =
      case start_worker(HelloClusterWorker.StatefulWorker, name) do
        {:ok, pid} ->
          pid

        {:error, {:already_started, pid}} ->
          pid
      end

    GenServer.call(pid, :greet)
  end

  @worker_starter {:via, Horde.Registry, {HelloCluster.Registry, HelloClusterWorker.Starter}}
  defp start_worker(module, arg), do: GenServer.call(@worker_starter, {:start_worker, {module, arg}})
end
