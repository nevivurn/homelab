{
  mkShell,

  # custom packages
  customPackages,

  ansible,
  ansible-lint,
  golangci-lint,
  opentofu,
  python3,
  python3Packages,
  talosctl,
}:

mkShell {
  packages = [
    ansible
    ansible-lint

    talosctl

    (opentofu.withPlugins (ps: with ps; [ infra ]))

    (python3.withPackages (ps: with ps; [ pyyaml ]))
    python3Packages.flake8
    python3Packages.mypy

    golangci-lint
  ];

  inputsFrom = customPackages;

  shellHook = ''
    export KUBECONFIG=$(pwd)/talos/_out/kubeconfig
    export TALOSCONFIG=$(pwd)/talos/_out/talosconfig
  '';
}
