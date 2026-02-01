{
  lib,
  config,
  ...
}:

let
  inherit (config) primary;
  v4prefix = "10.64.4${if primary then "1" else "2"}.";
  v6prefix = "fdbc:ba6a:38de:4${if primary then "1" else "2"}::";

  peers = {
    altais = {
      address = "2";
      public-key = [
        "0xsPcmKTLsF68NtaTDh45m5lbBr3AyMLZVgckNxT1UM="
        "mtrjUEpeiulV7ltHPAoXcLuRkDy2b7UZKgC6UmxgtXw="
      ];
    };
    edasich = {
      address = "3";
      public-key = [
        "Ib3YqWCoVOem0q4jNnFlLeSplFovcFDNhXiqADseeU0="
        "79vDmwvL+mK1rsXHXjxupInwQWXYg2l/+duiv5exoio="
      ];
    };
  };
in

{
  vyosConfig.interfaces.wireguard = {
    wg40 = {
      address = [
        "${v4prefix}1/24"
        "${v6prefix}1/64"
      ];
      port = "51820";

      peer = lib.mapAttrs (_: peer: {
        allowed-ips = [
          "${v4prefix}${peer.address}/32"
          "${v6prefix}${peer.address}/128"
        ];
        public-key = lib.elemAt peer.public-key (if primary then 0 else 1);
      }) peers;
    };
  };

  firewall.tables =
    let
      rule = {
        action = "accept";
        protocol = "udp";
        destination.port = "51820";
      };
    in
    {
      WAN-INGRESS.rules."140" = rule;
      LAN-INGRESS.rules."140" = rule;
      GUEST-INGRESS.rules."140" = rule;
    };
}
