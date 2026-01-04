{
  mkShell,

  # custom packages
  customPackages,

  # ansible
  ansible,
  ansible-lint,

  # cilium
  cilium-cli,
  hubble,

  # k8s
  k9s,

  # helm
  helmfile,
  kubernetes-helm,
  kubernetes-helmPlugins,
  wrapHelm,

  talosctl,
  python3,

  # opentofu
  opentofu,
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

    cilium-cli
    hubble

    helm'
    helmfile'

    k9s
    talosctl

    (opentofu.withPlugins (ps: with ps; [ infra ]))

    (python3.withPackages (
      ps: with ps; [
        dataclass-wizard
        flake8
        mypy
        pyyaml
        types-pyyaml
      ]
    ))
  ];

  inputsFrom = customPackages;

  shellHook = ''
    export KUBECONFIG=$(pwd)/talos/_out/kubeconfig
    export TALOSCONFIG=$(pwd)/talos/_out/talosconfig
  '';
}
