{ lib, ... }:

let
  allModules = lib.pipe (builtins.readDir ./.) [
    lib.attrNames
    (lib.filter (f: f != "default.nix"))
    (lib.map (f: ./${f}))
  ];
in

{
  imports = allModules;

  options.primary = lib.mkOption {
    type = lib.types.bool;
  };

  config.vyosConfig = {
    firewall = {
      global-options = {
        source-validation = "strict";
        ipv6-source-validation = "strict";
        state-policy = {
          established.action = "accept";
          related.action = "accept";
          invalid.action = "drop";
        };
      };
    };

    # non-critical dependencies on network infra
    system.domain-name = "inf.nevi.network";
    system.name-server = [
      "10.64.20.4"
      "10.64.20.5"
    ];
    service.ntp.server = [
      "10.64.20.4"
      "10.64.20.5"
    ];

    # default SSH config
    service.ssh = { };
    service.monitoring.prometheus.node-exporter = { };

    # upstream drops out on sustained >100Mbit/s upload
    qos = {
      policy.cake."EGRESS-BW".bandwidth = "100mbit";
      interface."eth0.99".egress = "EGRESS-BW";
    };
  };
}
