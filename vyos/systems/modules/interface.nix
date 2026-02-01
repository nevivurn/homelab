{
  lib,
  config,
  ...
}:

let
  inherit (config) primary;

  mtu = "9000";
  stdIds = [
    "10"
    "11"
    "20"
    "30"
  ];

  interfaces =
    lib.genAttrs stdIds (id: {
      address = [
        "10.64.${id}.${if primary then "2" else "3"}/24"
        "fdbc:ba6a:38de:${id}::${if primary then "2" else "3"}/64"
      ];
    })
    // {
      "200" = {
        address = [
          "10.64.200.${if primary then "1" else "2"}/24"
          "fdbc:ba6a:38de:200::${if primary then "1" else "2"}/64"
        ];
        ip.source-validation = "loose";
        ipv6.source-validation = "loose";
      };
      "99" = {
        address = [
          "dhcp"
          "dhcpv6"
        ];
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
        offload = [
          "gro"
          "gso"
          "sg"
          "tso"
        ];
        vif = interfaces;
      };
      loopback = "lo";
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
  };
}
