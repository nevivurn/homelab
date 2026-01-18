{
  mkShell,

  # custom packages
  customPackages,

  # ansible
  ansible,
  ansible-lint,

  talosctl,
  python3,

  # opentofu
  opentofu,

  # go
  golangci-lint,
}:

mkShell {
  packages = [
    ansible
    ansible-lint

    talosctl

    (opentofu.withPlugins (ps: with ps; [ infra ]))

    (python3.withPackages (ps: with ps; [ pyyaml ]))

    golangci-lint
  ];

  inputsFrom = customPackages;

  shellHook = ''
    export KUBECONFIG=$(pwd)/talos/_out/kubeconfig
    export TALOSCONFIG=$(pwd)/talos/_out/talosconfig
  '';
}
