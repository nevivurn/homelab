{
  lib,
  config,
  ...
}:

let
  inherit (config) primary;
  prefix = "fdbc:ba6a:38de:5${if primary then "1" else "2"}::";

  v4addr = "10.64.50.1";
  v6addr = "fdbc:ba6a:38de:50::1";

  peers = {
    alrakis = {
      host-name = "alrakis.priv.nevi.network";
      public-key = [
        "iRV6rA3PRiv5fl8Aee4esbDIll/5WzuZzpJ0XVh3tGU="
        "drA90hl3Zam64BfoMebswv9pOIftFG+AzdT88ah+3Rs="
      ];
      index = "2";
    };
    giausar = {
      host-name = "giausar.priv.nevi.network";
      public-key = [
        "EgXZBrQoTI2anXJDSi9PnvtxYq1f8QxvgyWTgtM62Q8="
        "3KEhFiRpGaUPG/yKa3+nINUgo4vG4phLWISIwQp7Qlo="
      ];
      index = "3";
    };
  };
in

{
  vyosConfig = {
    interfaces = {
      wireguard.wg50 = {
        address = [ "${prefix}1/64" ];

        peer = lib.mapAttrs (_: peer: {
          allowed-ips = [ "${prefix}${peer.index}/128" ];
          public-key = lib.elemAt peer.public-key (if primary then 0 else 1);
          inherit (peer) host-name;
          port = "605${if primary then "1" else "2"}";
        }) peers;
      };
      dummy.dum50 = {
        address = [
          "${v4addr}/32"
          "${v6addr}/128"
        ];
      };
    };

    load-balancing.haproxy = {
      service.PRX = {
        backend = "PRX";
        listen-address = [
          v4addr
          v6addr
        ];
        mode = "tcp";
        port = "443";
      };
      backend.PRX = {
        mode = "tcp";
        server = lib.mapAttrs (_: peer: {
          address = "${prefix}${peer.index}";
          port = "443";
          check.port = "443";
        }) peers;
      };
    };

    nat66.source.rule."50" = {
      outbound-interface.name = "wg50";
      translation.address = "masquerade";
    };
  };

  firewall = {
    groups = {
      address-group.PRX4 = [ v4addr ];
      ipv6-address-group.PRX6 = [ v6addr ];
    };
    tables.LAN-INGRESS.rules."310" = {
      action = "accept";
      protocol = "tcp";
      destination.port = "443";
      ipv4.destination.group.address-group = "PRX4";
      ipv6.destination.group.address-group = "PRX6";
    };
  };
}
