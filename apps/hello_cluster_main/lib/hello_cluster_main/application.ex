defmodule HelloClusterMain.Application do
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
      {Plug.Cowboy, scheme: :http, plug: HelloClusterMain.Plug, options: [port: http_port()]},
      {Cluster.Supervisor, [topologies]},
      {Horde.Registry, name: HelloCluster.Registry, keys: :unique, members: :auto}
    ]

    opts = [strategy: :one_for_one, name: HelloClusterMain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp http_port, do: "PORT" |> System.get_env("4000") |> String.to_integer()
end
