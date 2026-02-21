{
  # K8S API firewall rules
  firewall = {
    groups = {
      address-group.K8S-LB-addr4 = [ "10.64.31.0-10.64.31.255" ];
      ipv6-address-group.K8S-LB-addr6 = [ "fdbc:ba6a:38de:31::-fdbc:ba6a:38de:31:ffff:ffff:ffff:ffff" ];
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
  };
}
