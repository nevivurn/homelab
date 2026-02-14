{ config, ... }:

let
  inherit (config) primary;

  localAS = "65000";
  routerId = if primary then "10.64.200.1" else "10.64.200.2";
  peerAddr = if primary then "fdbc:ba6a:38de:200::2" else "fdbc:ba6a:38de:200::1";
in

{
  vyosConfig = {
    policy.route-map.DENY-ALL.rule."10".action = "deny";

    protocols.bgp = {
      system-as = localAS;
      parameters.router-id = routerId;

      address-family = [
        "ipv4-unicast"
        "ipv6-unicast"
      ];

      neighbor.${peerAddr} = {
        remote-as = "internal";
        address-family = [
          "ipv4-unicast"
          "ipv6-unicast"
        ];
      };

      listen.range."fdbc:ba6a:38de:30::/64".peer-group = "K8S-cilium";
      peer-group.K8S-cilium = {
        remote-as = "65001";
        graceful-restart = "enable";
        address-family = {
          # cilium CP does not install any routes, don't bother exporting
          ipv4-unicast.route-map.export = "DENY-ALL";
          ipv6-unicast.route-map.export = "DENY-ALL";
        };
      };
    };
  };
}
