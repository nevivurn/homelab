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
  sops,
  talhelper,
  talosctl,
}:

mkShell {
  packages = [
    ansible
    ansible-lint
    sops
    talhelper
    talosctl

    (opentofu.withPlugins (ps: with ps; [ infra ]))

    (python3.withPackages (ps: with ps; [ pyyaml ]))
    python3Packages.flake8
    python3Packages.mypy

    golangci-lint
  ];

  inputsFrom = customPackages;
}
