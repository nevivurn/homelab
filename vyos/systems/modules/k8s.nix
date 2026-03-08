{ lib, ... }:

let
  clusters = lib.genAttrs' [ 20 25 30 35 ] (idx: {
    name = "K8S-c${lib.toString idx}";
    value = {
      v4Address = "10.64.30.${lib.toString idx}";
      v6Address = "fdbc:ba6a:38de:30::${lib.toString idx}";
      backends = lib.map (idx: "fdbc:ba6a:38de:30::${lib.toString idx}") (lib.range (idx + 1) (idx + 4));
    };
  });
in

{
  # K8S API firewall rules
  firewall = {
    groups = {
      address-group = {
        K8S-LB-addr4 = [ "10.64.31.0-10.64.31.255" ];
        K8S-API4 = lib.mapAttrsToList (_: cls: cls.v4Address) clusters;
      };
      ipv6-address-group = {
        K8S-LB-addr6 = [ "fdbc:ba6a:38de:31::-fdbc:ba6a:38de:31:ffff:ffff:ffff:ffff" ];
        K8S-API6 = lib.mapAttrsToList (_: cls: cls.v6Address) clusters;
      };
    };
    tables.LAN-K8S.rules = {
      "210" = {
        # allow Talos API
        action = "accept";
        protocol = "tcp";
        destination.port = "6443,50000";
      };
      "300" = {
        # allow exposed LB services
        action = "accept";
        protocol = "tcp_udp";
        ipv4.destination.group.address-group = "K8S-LB-addr4";
        ipv6.destination.group.address-group = "K8S-LB-addr6";
      };
    };
    tables.LAN-INGRESS.rules."300" = {
      action = "accept";
      protocol = "tcp";
      destination.port = "6443";
      ipv4.destination.group.address-group = "K8S-API4";
      ipv6.destination.group.address-group = "K8S-API6";
    };
  };

  vyosConfig = {
    load-balancing.haproxy = {
      backend = lib.mapAttrs (cname: cls: {
        mode = "tcp";
        server = lib.listToAttrs (
          lib.imap0 (idx: server: {
            name = "${cname}-${lib.toString idx}";
            value = {
              address = server;
              port = "6443";
              check.port = "6443";
            };
          }) cls.backends
        );
      }) clusters;
      service = lib.mapAttrs (cname: cls: {
        mode = "tcp";
        port = "6443";
        backend = cname;
        listen-address = [
          cls.v4Address
          cls.v6Address
        ];
      }) clusters;
    };

    system.sysctl.parameter = {
      "net.ipv4.ip_nonlocal_bind".value = "1";
      "net.ipv6.ip_nonlocal_bind".value = "1";
    };

    high-availability.vrrp.group.K8S = {
      address = lib.mapAttrsToList (_: cls: "${cls.v4Address}/24") clusters;
      excluded-address = lib.mapAttrsToList (_: cls: "${cls.v6Address}/64") clusters;
    };
  };
}
