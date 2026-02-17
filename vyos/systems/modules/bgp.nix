{ config, ... }:

let
  inherit (config) primary;

  localAS = "65000";
  routerId = if primary then "10.64.200.1" else "10.64.200.2";
  peerAddr = if primary then "fdbc:ba6a:38de:200::2" else "fdbc:ba6a:38de:200::1";
in

{
  vyosConfig = {
    policy = {
      prefix-list.INTERNAL-v4.rule."10" = {
        action = "permit";
        prefix = "10.64.0.0/16";
        le = "32";
      };
      prefix-list6.INTERNAL-v6.rule."10" = {
        action = "permit";
        prefix = "fdbc:ba6a:38de::/48";
        le = "128";
      };

      route-map.DENY-ALL.rule."10".action = "deny";
      route-map.REDISTRIBUTE-INTERNAL.rule = {
        "10" = {
          action = "permit";
          match.ip.address.prefix-list = "INTERNAL-v4";
        };
        "20" = {
          action = "permit";
          match.ipv6.address.prefix-list = "INTERNAL-v6";
        };
      };
    };

    protocols.bgp = {
      system-as = localAS;
      parameters.router-id = routerId;

      address-family = {
        ipv4-unicast.redistribute.connected.route-map = "REDISTRIBUTE-INTERNAL";
        ipv6-unicast.redistribute.connected.route-map = "REDISTRIBUTE-INTERNAL";
      };

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
