{ lib, config, ... }:

let
  inherit (config) primary;

  groupIds = {
    HOME = "10";
    GUEST = "11";
    INFRA = "20";
    K8S = "30";
    ROUTER = "200";
  };

  # .1, .2, ... mappings:
  # For other zones: VIP, primary, backup
  # For ROUTER: primary, backup, [reserved], VIP
  groups = lib.mapAttrs (name: id: {
    interface = "eth0.${id}";
    vrid = id;
    v4address = if name == "ROUTER" then "10.64.${id}.4/24" else "10.64.${id}.1/24";
    v6address = if name == "ROUTER" then "fdbc:ba6a:38de:${id}::4/64" else "fdbc:ba6a:38de:${id}::1/64";
    priority = if primary then "100" else "90";
    peer-address =
      if name == "ROUTER" then
        "10.64.${id}.${if primary then "2" else "1"}"
      else
        "10.64.${id}.${if primary then "3" else "2"}";
  }) groupIds;
in

{
  vyosConfig = {
    high-availability.vrrp = {
      sync-group.ROUTER = {
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
        excluded-address.${v.v6address} = { };
        excluded-address."fe80::1/64" = { };
      }) groups;
    };

    service.conntrack-sync = {
      accept-protocol = {
        tcp = { };
        udp = { };
        icmp = { };
        icmp6 = { };
      };
      failover-mechanism.vrrp.sync-group = "ROUTER";
      interface.${groups.ROUTER.interface}.peer = groups.ROUTER.peer-address;
      startup-resync = { };
    };
  };
}
