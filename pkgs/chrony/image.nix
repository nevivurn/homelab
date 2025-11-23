{
  lib,
  dockerTools,
  tini,
  coreutils,
  chrony,
}:

dockerTools.buildLayeredImage {
  name = chrony.pname;
  tag = chrony.version;
  config = {
    Entrypoint = [
      (lib.getExe tini)
      "--"
      (lib.getExe' chrony "chronyd")
    ];
  };
  contents = [
    dockerTools.binSh
    dockerTools.fakeNss
    coreutils
    chrony
  ];
}
