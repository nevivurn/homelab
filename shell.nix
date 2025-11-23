{
  mkShell,
  ansible,
  ansible-lint,
  python3,
  talosctl,
}:

mkShell {
  packages = [
    ansible
    ansible-lint
    (python3.withPackages (
      ps: with ps; [
        dataclass-wizard
        flake8
        mypy
        pyyaml
        types-pyyaml
      ]
    ))
    talosctl
  ];
}
