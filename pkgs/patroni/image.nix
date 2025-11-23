{
  lib,
  dockerTools,
  tini,
  coreutils,
  patroni,
  postgresql_18,
}:

dockerTools.buildLayeredImage {
  name = patroni.pname;
  tag = patroni.version;
  config = {
    Entrypoint = [
      (lib.getExe tini)
      "--"
      (lib.getExe' patroni "patroni")
    ];
  };
  contents = [
    dockerTools.binSh
    dockerTools.fakeNss
    coreutils
    patroni
    postgresql_18
  ];
}
