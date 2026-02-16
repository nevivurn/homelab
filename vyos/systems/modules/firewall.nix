{ lib, ... }:

# general rule numbering
# 0~99 basic rules managed centrally
# 100~199 "infra" rules managed centrally
# 200~ distributed rules

let
  rules = {
    # allow basic pings & icmpv6
    allow-icmp = {
      action = "accept";
      ipv4.icmp.type-name = "echo-request";
      ipv6.protocol = "ipv6-icmp";
    };

    # allow ping only
    allow-ping = {
      action = "accept";
      ipv4.icmp.type-name = "echo-request";
      ipv6.icmpv6.type-name = "echo-request";
    };

    # allow VRRP from the master or backup
    allow-vrrp.ipv4 = {
      action = "accept";
      protocol = "vrrp";
      source.group.address-group = "ROUTER-addr4";
    };

    # allow SSH
    allow-ssh = {
      action = "accept";
      protocol = "tcp";
      destination.port = "22";
    };
  };

  rulesets = {
    # allow access to DHCP
    dhcp-services = {
      "110" = {
        # allow DHCP relay traffic
        action = "accept";
        protocol = "udp";
        ipv4 = {
          source.group.address-group = "DHCP4-RELAY";
          destination.group.address-group = "INFRA-addr4";
          destination.port = "67";
        };
        ipv6 = {
          source.group.address-group = "DHCP6-RELAY";
          destination.group.address-group = "INFRA-addr6";
          destination.port = "547";
        };
      };
    };
    # allow access to other infra services (DNS, NTP)
    infra-services = rulesets.dhcp-services // {
      "120" = {
        # allow DNS, NTP, etc.
        action = "accept";
        protocol = "tcp_udp";
        destination.group.port-group = "INFRA-port";
        ipv4.destination.group.address-group = "INFRA-addr4";
        ipv6.destination.group.address-group = "INFRA-addr6";
      };
    };
  };
in
{
  firewall = {
    groups = {
      address-group = {
        INFRA-addr4 = [ "10.64.20.4-10.64.20.5" ];
        DHCP4-RELAY = [
          "10.64.1.4-10.64.1.5" # MGMT
          "10.64.10.4-10.64.10.5" # HOME
          "10.64.11.4-10.64.11.5" # GUEST
          "10.64.30.4-10.64.30.5" # K8S
        ];
        ROUTER-addr4 = [
          "10.64.1.2-10.64.1.3" # MGMT
          "10.64.10.2-10.64.10.3" # HOME
          "10.64.11.2-10.64.11.3" # GUEST
          "10.64.20.2-10.64.20.3" # INFRA
          "10.64.30.2-10.64.30.3" # K8S
          "10.64.200.1-10.64.200.2" # ROUTER
        ];
        K8S-LB-addr4 = [ "10.64.31.0-10.64.31.255" ];
      };
      ipv6-address-group = {
        INFRA-addr6 = [ "fdbc:ba6a:38de:20::4-fdbc:ba6a:38de:20::5" ];
        DHCP6-RELAY = [
          "fdbc:ba6a:38de:1::4-fdbc:ba6a:38de:1::5" # MGMT
          "fdbc:ba6a:38de:10::4-fdbc:ba6a:38de:10::5" # HOME
          "fdbc:ba6a:38de:11::4-fdbc:ba6a:38de:11::5" # GUEST
          "fdbc:ba6a:38de:30::4-fdbc:ba6a:38de:30::5" # K8S
        ];
        ROUTER-addr6 = [
          # ROUTER peers
          "fdbc:ba6a:38de:200::1-fdbc:ba6a:38de:200::2"
          # K8S node range - for cilium BGP
          "fdbc:ba6a:38de:30::-fdbc:ba6a:38de:30:ffff:ffff:ffff:ffff"
        ];
        K8S-LB-addr6 = [ "fdbc:ba6a:38de:31::-fdbc:ba6a:38de:31:ffff:ffff:ffff:ffff" ];
      };
      port-group = {
        INFRA-port = [
          "53"
          "123"
        ];
      };
    };

    zones = {
      WAN = {
        members = [ "eth0.99" ];
        intra-zone-filtering = "drop";
      };
      LOCAL.local-zone = true;
      MGMT.members = [ "eth0" ];
      ROUTER.members = [ "eth0.200" ];
      HOME.members = [
        "eth0.10"
        "wg40"
      ];
      GUEST.members = [ "eth0.11" ];
      INFRA.members = [ "eth0.20" ];
      K8S.members = [ "eth0.30" ];
      PROXY = {
        members = [ "wg50" ];
        intra-zone-filtering = "drop";
      };
    };

    tables = {
      # egress to WAN
      EGRESS-WAN.default-action = "accept";
      # egress from LOCAL
      LOCAL-EGRESS.default-action = "accept";
      # LAN -> ROUTER (trust that ROUTER is capable of filtering traffic)
      LAN-ROUTER.default-action = "accept";

      LAN-MGMT = {
        default-action = "drop";
        rules = {
          "10" = rules.allow-icmp;
          "100" = rules.allow-vrrp;
          "200" = rules.allow-ssh;
          "210" = {
            # allow management interfaces
            action = "accept";
            protocol = "tcp";
            destination.port = "443";
            # NOTE: needs masquerade, check below
          };
          "220" = {
            # allow Proxmox
            action = "accept";
            protocol = "tcp";
            destination.port = "8006";
          };
        };
      };

      # LAN -> LOCAL
      LAN-INGRESS = {
        default-action = "drop";
        rules = {
          "10" = rules.allow-icmp;
          "100" = rules.allow-vrrp;
          "101" = {
            # allow conntrack-sync
            ipv4 = {
              action = "accept";
              protocol = "udp";
              destination.port = "3780";
              source.group.address-group = "ROUTER-addr4";
            };
          };
          "102" = {
            # allow BGP
            ipv6 = {
              action = "accept";
              protocol = "tcp";
              destination.port = "179";
              source.group.address-group = "ROUTER-addr6";
            };
          };
          "200" = rules.allow-ssh;
          "210" = {
            action = "accept";
            protocol = "tcp";
            destination.port = "9100";
          };
        };
      };

      # GUEST -> LOCAL
      GUEST-INGRESS = {
        default-action = "drop";
        rules = {
          "10" = rules.allow-icmp;
          "100" = rules.allow-vrrp;
        };
      };

      # WAN -> LOCAL
      WAN-INGRESS = {
        default-action = "drop";
        rules."10" = rules.allow-icmp;
      };

      LAN-HOME = {
        default-action = "drop";
        rules = {
          "10" = rules.allow-ping;
          "200" = rules.allow-ssh;
        };
      };

      LAN-GUEST = {
        default-action = "drop";
        rules = {
          "10" = lib.recursiveUpdate rules.allow-ping {
            # allow pinging DHCP relays
            ipv4.destination.group.address-group = "DHCP4-RELAY";
            ipv6.destination.group.address-group = "DHCP6-RELAY";
          };
          "200" = lib.recursiveUpdate rules.allow-ssh {
            # allow ssh into DHCP relays
            ipv4.destination.group.address-group = "DHCP4-RELAY";
            ipv6.destination.group.address-group = "DHCP6-RELAY";
          };
        };
      };

      WAN-INFRA = {
        default-action = "drop";
      };

      LAN-INFRA = {
        default-action = "drop";
        rules = rulesets.infra-services // {
          "10" = rules.allow-ping;
          "200" = rules.allow-ssh;
          "220" = {
            # allow Caddy (infra proxy)
            action = "accept";
            protocol = "tcp_udp";
            destination.port = "443";
            ipv4.destination.group.address-group = "INFRA-addr4";
            ipv6.destination.group.address-group = "INFRA-addr6";
          };
        };
      };

      GUEST-INFRA = {
        default-action = "drop";
        rules = rulesets.dhcp-services // {
          "10" = lib.recursiveUpdate rules.allow-ping {
            # allow pinging infra servers
            ipv4.destination.group.address-group = "INFRA-addr4";
            ipv6.destination.group.address-group = "INFRA-addr6";
          };
        };
      };

      LAN-K8S = {
        default-action = "drop";
        rules = {
          "10" = rules.allow-ping;
          "200" = rules.allow-ssh;
          "210" = {
            # allow Talos API
            action = "accept";
            protocol = "tcp";
            destination.port = "50000";
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
    };

    mappings = {
      # Egress to WAN
      LOCAL.WAN = "EGRESS-WAN";
      MGMT.WAN = "EGRESS-WAN";
      HOME.WAN = "EGRESS-WAN";
      GUEST.WAN = "EGRESS-WAN";
      INFRA.WAN = "EGRESS-WAN";
      K8S.WAN = "EGRESS-WAN";

      # Egress to PROXY
      LOCAL.PROXY = "EGRESS-WAN";
      HOME.PROXY = "EGRESS-WAN";
      INFRA.PROXY = "EGRESS-WAN";
      K8S.PROXY = "EGRESS-WAN";

      # Egress from LOCAL
      LOCAL.ROUTER = "LOCAL-EGRESS";
      LOCAL.MGMT = "LOCAL-EGRESS";
      LOCAL.HOME = "LOCAL-EGRESS";
      LOCAL.GUEST = "LOCAL-EGRESS";
      LOCAL.INFRA = "LOCAL-EGRESS";
      LOCAL.K8S = "LOCAL-EGRESS";

      # Ingress to LOCAL
      WAN.LOCAL = "WAN-INGRESS";
      ROUTER.LOCAL = "LAN-INGRESS";
      MGMT.LOCAL = "LAN-INGRESS";
      HOME.LOCAL = "LAN-INGRESS";
      INFRA.LOCAL = "LAN-INGRESS";
      K8S.LOCAL = "LAN-INGRESS";
      GUEST.LOCAL = "GUEST-INGRESS";

      HOME.ROUTER = "LAN-ROUTER";

      HOME.MGMT = "LAN-MGMT";

      INFRA.HOME = "LAN-HOME";
      K8S.HOME = "LAN-HOME";

      HOME.GUEST = "LAN-GUEST";
      INFRA.GUEST = "LAN-GUEST";

      WAN.INFRA = "WAN-INFRA";
      MGMT.INFRA = "LAN-INFRA";
      HOME.INFRA = "LAN-INFRA";
      GUEST.INFRA = "GUEST-INFRA";
      K8S.INFRA = "LAN-INFRA";

      HOME.K8S = "LAN-K8S";
      INFRA.K8S = "LAN-K8S";
    };
  };

  # mgmt devices expect traffic from the same network segment, masquerade
  vyosConfig = {
    nat.source.rule = {
      "20" = {
        outbound-interface.name = "eth0";
        translation.address = "masquerade";
      };
    };
    nat66.source.rule = {
      "20" = {
        outbound-interface.name = "eth0";
        translation.address = "masquerade";
      };
    };
  };
}
