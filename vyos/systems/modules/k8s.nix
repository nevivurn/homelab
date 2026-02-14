{ lib, ... }:

let
  v4addr = "10.64.30.10";
  v6addr = "fdbc:ba6a:38de:30::10";

  hosts = {
    k8s-master11 = "fdbc:ba6a:38de:30::11";
    k8s-master12 = "fdbc:ba6a:38de:30::12";
    k8s-master13 = "fdbc:ba6a:38de:30::13";
  };
in

{
  # K8S API firewall rules
  firewall = {
    groups = {
      address-group.K8S-API4 = [ v4addr ];
      ipv6-address-group.K8S-API6 = [ v6addr ];
    };
    tables.LAN-INGRESS.rules."300" = {
      action = "accept";
      protocol = "tcp";
      destination.port = "443";
      ipv4.destination.group.address-group = "K8S-API4";
      ipv6.destination.group.address-group = "K8S-API6";
    };
  };

  vyosConfig = {
    # primary HAProxy config
    load-balancing.haproxy = {
      backend.K8S-API = {
        mode = "tcp";
        server = lib.mapAttrs (_: addr: {
          address = addr;
          port = "6443";
          check.port = "6443";
        }) hosts;
      };
      service.K8S-API = {
        backend = "K8S-API";
        listen-address = [
          v4addr
          v6addr
        ];
        mode = "tcp";
        port = "443";
      };
    };

    # allow haproxy to listen on non-local addresses (when we are not the VRRP master)
    system.sysctl.parameter = {
      "net.ipv4.ip_nonlocal_bind".value = "1";
      "net.ipv6.ip_nonlocal_bind".value = "1";
    };

    # VIP VRRP
    high-availability.vrrp.group.K8S = {
      address = [ "${v4addr}/24" ];
      excluded-address = [ "${v6addr}/64" ];
    };
  };
}
