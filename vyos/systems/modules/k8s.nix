{ lib, ... }:

let
  services = {
    K8S-API4 = {
      addr = "10.64.30.10";
      family = "ipv4";
      hosts = {
        k8s-master11 = "10.64.30.11";
        k8s-master12 = "10.64.30.12";
        k8s-master13 = "10.64.30.13";
      };
    };
    K8S-API6 = {
      addr = "fdbc:ba6a:38de:30::10";
      family = "ipv6";
      hosts = {
        k8s-master11 = "fdbc:ba6a:38de:30::11";
        k8s-master12 = "fdbc:ba6a:38de:30::12";
        k8s-master13 = "fdbc:ba6a:38de:30::13";
      };
    };
  };

  v4Services = lib.filterAttrs (_: v: v.family == "ipv4") services;
  v6Services = lib.filterAttrs (_: v: v.family == "ipv6") services;

  servicePort = "443";
  backendPort = "6443";
in

{
  # K8S API firewall rules
  firewall = {
    groups = {
      address-group = lib.mapAttrs (_: v: [ v.addr ]) v4Services;
      ipv6-address-group = lib.mapAttrs (_: v: [ v.addr ]) v6Services;
    };
    tables.LAN-INGRESS.rules."300" = {
      action = "accept";
      protocol = "tcp";
      destination.port = servicePort;
      ipv4.destination.group.address-group = "K8S-API4";
      ipv6.destination.group.address-group = "K8S-API6";
    };
  };

  vyosConfig = {
    # primary HAProxy config
    load-balancing.haproxy = {
      backend =
        let
          genBackend = hosts: {
            mode = "tcp";
            server = lib.mapAttrs (_: addr: {
              address = addr;
              port = backendPort;
              check.port = backendPort;
            }) hosts;
          };
        in
        lib.mapAttrs (_: v: genBackend v.hosts) services;
      service =
        let
          genService = name: addr: {
            backend = name;
            listen-address = addr;
            mode = "tcp";
            port = servicePort;
          };
        in
        lib.mapAttrs (k: v: genService k v.addr) services;
    };

    # allow haproxy to listen on non-local addresses (when we are not the VRRP master)
    system.sysctl.parameter = {
      "net.ipv4.ip_nonlocal_bind".value = "1";
      "net.ipv6.ip_nonlocal_bind".value = "1";
    };

    # VIP VRRP
    high-availability.vrrp.group.K8S = {
      address = lib.mapAttrs' (_: v: {
        name = "${v.addr}/24";
        value = { };
      }) v4Services;
      excluded-address = lib.mapAttrs' (_: v: {
        name = "${v.addr}/64";
        value = { };
      }) v6Services;
    };
  };
}
