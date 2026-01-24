{ lib, libVyos, config, ... }:

let
  inherit (config) primary;
  inherit (libVyos) listToVyosAttrs;

  mtu = "9000";
  stdIds = [
    "10"
    "11"
    "20"
    "30"
  ];

  # Static routes via ROUTER network gateway
  gatewayV4 = "10.64.200.3";
  gatewayV6 = "fdbc:ba6a:38de:200::3";
  staticRoutesV4 = [
    "10.42.42.0/24"
    "10.42.43.0/24"
    "10.89.0.0/16"
    "10.90.0.0/16"
    "10.91.0.0/16"
    "10.92.0.0/16"
    "192.168.2.0/24"
  ];
  staticRoutesV6 = [
    "fdbc:ba6a:38de::/62"
  ];

  interfaces =
    lib.genAttrs stdIds (id: {
      address = {
        "10.64.${id}.${if primary then "2" else "3"}/24" = { };
        "fdbc:ba6a:38de:${id}::${if primary then "2" else "3"}/64" = { };
      };
    })
    // {
      "200" = {
        address = {
          "10.64.200.1/24" = { };
          "fdbc:ba6a:38de:200::1/64" = { };
        };
      };
      "99" = {
        address = {
          dhcp = { };
          dhcpv6 = { };
        };
        # WAN interface, adjust MTU & clamp
        mtu = "1500";
        ip.adjust-mss = "clamp-mss-to-pmtu";
        ipv6.adjust-mss = "clamp-mss-to-pmtu";
      };
    };
in

{
  vyosConfig = {
    # basic interface config
    interfaces = {
      ethernet.eth0 = {
        inherit mtu;
        offload = {
          "gro" = { };
          "gso" = { };
          "sg" = { };
          "tso" = { };
        };
        vif = interfaces;
      };
      loopback.lo = { };
    };

    # RAs: advertise routes, MTU, disable SLAAC
    service.router-advert.interface = lib.genAttrs' stdIds (id: {
      name = "eth0.${id}";
      value = {
        link-mtu = mtu;
        source-address = "fe80::1";
        managed-flag = { };
        other-config-flag = { };
        prefix."::/64" = "no-autonomous-flag";
      };
    });

    # WAN masquerade
    nat.source.rule."10" = {
      outbound-interface.name = "eth0.99";
      translation.address = "masquerade";
    };
    nat66.source.rule."10" = {
      outbound-interface.name = "eth0.99";
      translation.address = "masquerade";
    };

    # Static routes
    protocols.static = {
      route = lib.genAttrs staticRoutesV4 (_: { next-hop.${gatewayV4} = { }; });
      route6 = lib.genAttrs staticRoutesV6 (_: { next-hop.${gatewayV6} = { }; });
    };
  };
}
