{
  lib,
  config,
  ...
}:

let
  inherit (config) primary;

  # NOTE: experimenting w/ free tunnelbrokers before we get "real" ipv6 routing
  # This exposes (external) addresses, but it's all WAN-side & temporary anyways.
  tunnelCfg =
    if primary then
      {
        remote = "64.62.134.130";
        address = "2001:470:66:33::2/64";
        transit = "2001:470:66:33::/64";
        route = "2001:470:4812::/48";
      }
    else
      {
        remote = "103.172.116.132";
        address = "2a11:6c7:f07:15f::2/64";
        transit = "2a11:6c7:f07:15f::/64";
        route = "2a11:6c7:3001:5f00::/56";
      };

  mappings =
    if primary then
      [
        {
          src = "fdbc:ba6a:38de::/48";
          dst = "2001:470:4812::/48";
        }
      ]
    else
      [
        {
          # MGMT
          src = "fdbc:ba6a:38de:1::/64";
          dst = "2a11:6c7:3001:5f01::/64";
        }
        {
          # HOME
          src = "fdbc:ba6a:38de:10::/64";
          dst = "2a11:6c7:3001:5f10::/64";
        }
        {
          # GUEST
          src = "fdbc:ba6a:38de:11::/64";
          dst = "2a11:6c7:3001:5f11::/64";
        }
        {
          # INFRA
          src = "fdbc:ba6a:38de:20::/64";
          dst = "2a11:6c7:3001:5f20::/64";
        }
        {
          # K8S
          src = "fdbc:ba6a:38de:30::/64";
          dst = "2a11:6c7:3001:5f30::/64";
        }
        {
          # WG41
          src = "fdbc:ba6a:38de:41::/64";
          dst = "2a11:6c7:3001:5f41::/64";
        }
        {
          # WG42
          src = "fdbc:ba6a:38de:42::/64";
          dst = "2a11:6c7:3001:5f42::/64";
        }
        {
          # ROUTER
          src = "fdbc:ba6a:38de:200::/64";
          dst = "2a11:6c7:3001:5fc8::/64";
        }
      ];
in

{
  vyosConfig = {
    interfaces.tunnel.tun99 = {
      encapsulation = "sit";
      # source-address manual
      remote = tunnelCfg.remote;
      address = tunnelCfg.address;
      mtu = "1480";
      ip.adjust-mss = "clamp-mss-to-pmtu";
      ipv6.adjust-mss = "clamp-mss-to-pmtu";
    };

    protocols.static.route6."::/0".interface."tun99" = { };
    protocols.static.route6.${tunnelCfg.route}.blackhole = { };

    policy.prefix-list6.INTERNAL-v6.rule = lib.listToAttrs (
      lib.imap0
        (i: p: {
          name = toString (20 + i);
          value = {
            action = "permit";
            prefix = p;
          };
        })
        [
          tunnelCfg.transit
          tunnelCfg.route
        ]
    );

    nat66.source.rule = lib.listToAttrs (
      lib.imap1 (i: m: {
        name = toString (10 + i);
        value = {
          outbound-interface.name = "tun99";
          source.prefix = m.src;
          translation.address = m.dst;
        };
      }) mappings
    );

    nat66.destination.rule = lib.listToAttrs (
      lib.imap1 (i: m: {
        name = toString (10 + i);
        value = {
          inbound-interface.name = "tun99";
          destination.address = m.dst;
          translation.address = m.src;
        };
      }) mappings
    );
  };

  firewall = {
    zones.WAN.members = [ "tun99" ];
    tables.WAN-INGRESS.rules."20" = {
      ipv4 = {
        action = "accept";
        protocol = "41";
        source.address = tunnelCfg.remote;
      };
    };
  };
}
