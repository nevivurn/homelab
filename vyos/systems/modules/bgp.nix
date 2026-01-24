{ config, ... }:

let
  inherit (config) primary;

  localAS = "65000";
  routerId = if primary then "10.64.200.1" else "10.64.200.2";
  peerAddr = if primary then "10.64.200.2" else "10.64.200.1";
in

{
  vyosConfig.protocols.bgp = {
    system-as = localAS;
    parameters.router-id = routerId;

    neighbor.${peerAddr} = {
      remote-as = "internal";
      address-family = {
        ipv4-unicast = { };
        ipv6-unicast = { };
      };
    };

    listen.range."fdbc:ba6a:38de:30::/64".peer-group = "K8S-cilium";
    peer-group.K8S-cilium = {
      remote-as = "65001";
      password = "secret"; # TODO(nevivurn): generate real secret
      graceful-restart.enable = { };
      address-family = {
        ipv4-unicast = { };
        ipv6-unicast = { };
      };
    };
  };
}
