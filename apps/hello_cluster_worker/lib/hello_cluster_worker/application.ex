defmodule HelloClusterWorker.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    topologies = [
      hello_cluster: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies]},
      {Horde.Registry, name: HelloCluster.Registry, keys: :unique, members: :auto},
      {Horde.DynamicSupervisor, name: HelloClusterWorker.DynamicSupervisor, strategy: :one_for_one, members: :auto},
      # We could just directly start HelloClusterWorker.Starter under the application supervisor,
      # but in that case it won't be restarted on other nodes if this node crashes, so we start it
      # under a Horde supervisor instead:
      %{
        id: HelloClusterWorker.Starter,
        start: {Task, :start_link, [__MODULE__, :start_starter_under_horde_supervisor, []]},
        restart: :transient
      }
    ]

    opts = [strategy: :rest_for_one, name: HelloClusterWorker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_starter_under_horde_supervisor do
    Horde.DynamicSupervisor.start_child(HelloClusterWorker.DynamicSupervisor, HelloClusterWorker.Starter)
  end
end
