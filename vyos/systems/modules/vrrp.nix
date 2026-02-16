{ lib, config, ... }:

let
  inherit (config) primary;

  groupIds = {
    MGMT = "1";
    HOME = "10";
    GUEST = "11";
    INFRA = "20";
    K8S = "30";
  };

  # VIP, primary, backup
  groups = lib.mapAttrs (name: id: {
    interface = if id == "1" then "eth0" else "eth0.${id}";
    vrid = id;
    v4address = "10.64.${id}.1/24";
    v6address = "fdbc:ba6a:38de:${id}::1/64";
    priority = if primary then "100" else "90";
    peer-address = "10.64.${id}.${if primary then "3" else "2"}";
  }) groupIds;
in

{
  vyosConfig = {
    high-availability.vrrp = {
      sync-group.GATEWAY = {
        member = lib.mapAttrs (_: _: { }) groups;
      };
      group = lib.mapAttrs (_: v: {
        inherit (v)
          interface
          vrid
          priority
          peer-address
          ;
        address = v.v4address;
        excluded-address = [
          v.v6address
          "fe80::1/64"
        ];
      }) groups;
    };

    service.conntrack-sync = {
      accept-protocol = [
        "tcp"
        "udp"
        "icmp"
        "icmp6"
      ];
      failover-mechanism.vrrp.sync-group = "GATEWAY";
      interface."eth0.200".peer = "10.64.200.${if primary then "2" else "1"}";
      startup-resync = { };
      disable-external-cache = { };
    };
  };
}
