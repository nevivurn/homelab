{
  mkShell,
  ansible,
  ansible-lint,
}:

mkShell {
  packages = [
    ansible
    ansible-lint
  ];
}
