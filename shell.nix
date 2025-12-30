{
  mkShell,
  ansible,
  ansible-lint,
  cilium-cli,
  k9s,
  python3,
  talosctl,
}:

mkShell {
  packages = [
    ansible
    ansible-lint
    cilium-cli
    k9s
    talosctl
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
}
