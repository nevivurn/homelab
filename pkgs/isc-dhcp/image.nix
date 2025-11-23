{
  lib,
  dockerTools,
  tini,
  coreutils,
  isc-dhcp,
}:

dockerTools.buildLayeredImage {
  name = isc-dhcp.pname + "-dhcrelay";
  tag = isc-dhcp.version;
  config = {
    Entrypoint = [
      (lib.getExe tini)
      "--"
      (lib.getExe' isc-dhcp "dhcrelay")
    ];
  };
  contents = [
    dockerTools.binSh
    dockerTools.fakeNss
    coreutils
    isc-dhcp
  ];
}
