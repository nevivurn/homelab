{
  vyosConfig = {
    nat.destination.rule."100" = {
      inbound-interface.name = "eth0.99";
      protocol = "tcp_udp";
      destination.port = "5555";
      translation.address = "10.64.20.20";
    };
    nat66.destination.rule."100" = {
      inbound-interface.name = "eth0.99";
      protocol = "tcp_udp";
      destination.port = "5555";
      translation.address = "fdbc:ba6a:38de:20::20";
    };
  };

  firewall.tables = {
    LAN-INFRA.rules."300" = {
      action = "accept";
      protocol = "tcp_udp";
      destination.port = "111,443,2049,4000-4002";
      ipv4.destination.address = "10.64.20.20";
      ipv6.destination.address = "fdbc:ba6a:38de:20::20";
    };
    WAN-INFRA.rules."310" = {
      action = "accept";
      connection-status.nat = "destination";
      ipv4.destination.address = "10.64.20.20";
      ipv6.destination.address = "fdbc:ba6a:38de:20::20";
    };
  };
}
