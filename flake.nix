{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";

        releases =
          let
            inherit (pkgs) lib;

            packages = pkgs.beamPackages;

            version = "0.1.0";
            src = ./.;

            mixFodDeps = packages.fetchMixDeps {
              inherit src version;

              pname = "mix-deps-hello_cluster";
              sha256 = "sha256-hGZUCiupbTf4wybPv33RC1j/lvpt4rRlD9VHpqPjCOA=";
            };

            make_release = pname: packages.mixRelease {
              inherit version src mixFodDeps pname;

              installPhase = ''
                runHook preInstall
                mix release --no-deps-check --path "$out" ${pname}
                runHook postInstall
              '';
            };
          in lib.genAttrs [ "hello_cluster_main" "hello_cluster_worker" ] make_release;

        hello_cluster_ctl =
          let
            procfile = pkgs.writeText "Procfile" ''
              main: ${releases.hello_cluster_main}/bin/hello_cluster_main start_iex
              worker-1: RELEASE_NODE=hello_cluster_worker_1 ${releases.hello_cluster_worker}/bin/hello_cluster_worker start_iex
              worker-2: RELEASE_NODE=hello_cluster_worker_2 ${releases.hello_cluster_worker}/bin/hello_cluster_worker start_iex
            '';

            package = pkgs.writeShellScriptBin "hello_cluster_ctl" ''
              export OVERMIND_PORT=4000
              export OVERMIND_STOP_SIGNALS="main=QUIT,worker-1=QUIT,worker-2=QUIT"
              export OVERMIND_PROCFILE=${procfile}
              export OVERMIND_SOCKET="''${OVERMIND_SOCKET:-/tmp/hello_cluster_ctl.sock}"

              export RELEASE_COOKIE="''${RELEASE_COOKIE:-secret}"

              exec ${pkgs.overmind}/bin/overmind "$@"
            '';
          in {
            type = "app";
            program = "${package}/bin/hello_cluster_ctl";
          };
      in {
        packages = releases;

        apps =
          let
            make_release_app = name: package: {
              type = "app";
              program = "${package}/bin/${name}";
            };
          in builtins.mapAttrs make_release_app releases // {
            inherit hello_cluster_ctl;
          };

        defaultApp = hello_cluster_ctl;

        devShell = pkgs.mkShell {
          name = "hello_cluster";

          buildInputs = with pkgs; [
            elixir
            elixir_ls
            erlang
            curl
            xh
          ];

          ERL_AFLAGS = "-kernel shell_history enabled";
          TERM = "xterm-256color";
        };
      }
    );
}
