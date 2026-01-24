{ lib, ... }:

{
  imports = [
    ./modules/bgp.nix
    ./modules/firewall.nix
    ./modules/interface.nix
    ./modules/k8s.nix
    ./modules/vrrp.nix
  ];

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
    system.name-server = {
      "10.64.20.4" = { };
      "10.64.20.5" = { };
    };
    service.ntp.server = {
      "10.64.20.4" = { };
      "10.64.20.5" = { };
    };

    # default SSH config
    service.ssh = { };

    # upstream drops out on sustained >100Mbit/s upload
    qos = {
      policy.cake."EGRESS-BW".bandwidth = "100mbit";
      interface."eth0.99".egress = "EGRESS-BW";
    };
  };
}
