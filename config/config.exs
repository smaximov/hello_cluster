import Config

config :logger,
  compile_time_purge_matching: [
    # Silence "unable to connect to :nonode@nohost" warnings:
    [module: Cluster.Logger, function: "warn/2"]
  ]
