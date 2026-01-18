{
  mkShell,

  # custom packages
  customPackages,

  # ansible
  ansible,
  ansible-lint,

  # helm
  helmfile,
  kubernetes-helm,
  kubernetes-helmPlugins,
  wrapHelm,

  talosctl,
  python3,

  # opentofu
  opentofu,

  # go
  golangci-lint,
}:

let
  helmfile-plugins = with kubernetes-helmPlugins; [
    helm-diff
    helm-git
    helm-s3
    helm-secrets
  ];
  helm' = wrapHelm kubernetes-helm { plugins = helmfile-plugins; };
  helmfile' = helmfile.override {
    inherit (helm'.passthru) pluginsDir;
  };
in

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
