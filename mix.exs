defmodule HelloCluster.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        hello_cluster_main: [
          include_executables_for: [:unix],
          applications: [
            hello_cluster_main: :permanent
          ]
        ],
        hello_cluster_worker: [
          include_executables_for: [:unix],
          applications: [
            hello_cluster_worker: :permanent
          ]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end
