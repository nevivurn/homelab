{
  mkShell,

  # custom packages
  customPackages,

  ansible,
  ansible-lint,
  cilium-cli,
  clusterctl,
  crane,
  gh,
  golangci-lint,
  helmfile,
  hubble,
  kubernetes-helm,
  kubernetes-helmPlugins,
  kustomize,
  opentofu,
  python3,
  python3Packages,
  sops,
  talhelper,
  talosctl,
  wrapHelm,
  yq-go,
}:

let
  kubernetes-helm' = wrapHelm kubernetes-helm {
    plugins = with kubernetes-helmPlugins; [
      helm-diff
      helm-git
      helm-s3
      helm-secrets
    ];
  };
  helmfile' = helmfile.override {
    inherit (kubernetes-helm'.passthru) pluginsDir;
  };
in

mkShell {
  packages = [
    ansible
    ansible-lint
    cilium-cli
    clusterctl
    crane
    gh
    golangci-lint
    helmfile'
    hubble
    kustomize
    sops
    talhelper
    talosctl
    yq-go

    (opentofu.withPlugins (ps: with ps; [ infra ]))

    (python3.withPackages (ps: with ps; [ pyyaml ]))
    python3Packages.flake8
    python3Packages.mypy
  ];

  inputsFrom = customPackages;
}
