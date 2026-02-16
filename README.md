# homelab

## Addressing

Generally, everything is in `10.64.0.0/16` and `fdbc:ba6a:38de::/48`.

VLAN | Name                     | DNS                | IPv4           | IPv6
---  | ---                      | ---                | ---            | ---
1    | MGMT                     | mgmt.nevi.network  | 10.64.1.0/24   | fdbc:ba6a:38de:1::/64
10   | HOME                     | home.nevi.network  | 10.64.10.0/24  | fdbc:ba6a:38de:10::/64
11   | GUEST                    | guest.nevi.network | 10.64.11.0/24  | fdbc:ba6a:38de:11::/64
20   | INFRA                    | inf.nevi.network   | 10.64.20.0/24  | fdbc:ba6a:38de:20::/64
30   | Kubernetes nodes         | k8s.nevi.network   | 10.64.30.0/24  | fdbc:ba6a:38de:30::/64
30   | Kubernetes loadbalancers | ---                | 10.64.31.0/24  | fdbc:ba6a:38de:31::/64
30   | Kubernetes pods          | ---                | 10.64.128.0/20 | fdbc:ba6a:38de:32::/64
---  | ClusterIPs               | svc.cluster.local  | 172.30.0.0/16  | fdbc:ba6a:38de:33::/64
200  | ROUTER                   |                    | 10.64.200.0/24 | fdbc:ba6a:38de:200::/64

DHCP ranges are
- IPv4: `.100 ~ .200`
- IPv6: `:d6d6::/80`

### Reserved ranges

CIDR                | Notes
---                 | ---
10.42.43.0/24       | legacy proxy
172.20.0.0/14       | dn42

## Network architecture

### Routers

Redundant VyOS routers, with VRRP & conntrack-sync HA.

### Network Services

net01..net03 running

- etcd
- Patroni / PostgreSQL / HAProxy
- Kea DHCP
- PowerDNS
- chrony

### Infra subnet

Address  | Host    | Notes
---      | ---     | ---
.1       | gateway | VRRP
.2       | rtr01   |
.3       | rtr02   |
.4       | net01   | DHCP, DNS, NTP
.5       | net02   | DHCP, DNS, NTP
.6       | net03   | quorum
.10      | net     | VIP
.90~.99  | HW      | various hardware management interfaces

### Other subnets

Address | Host    | Notes
---     | ---     | ---
.1      | gateway | VRRP
.2      | rtr01   |
.3      | rtr02   |
.4      | relay01 | DHCP relay to net01
.5      | relay02 | DHCP relay to net02

### Kubernetes

Address | Host    | Notes
---     | ---     | ---
.1      | gateway | VRRP
.2      | rtr01   |
.3      | rtr02   |
.4      | relay01 | DHCP relay to net01
.5      | relay02 | DHCP relay to net02
.20     |         | control plane VIP

#### Notes

- We currently drop connections to the k8s apiserver VIP on router failover
  because the connections are terminated (proxied) on the routers themselves.
  - We could avoid this with eg. IPVS but we run into issues with hairpin
    connections or weirdness in the return-path.
    - We could have a separate set of hosts running just the k8s loadbalancer,
      but the k8s apiserver is not super critical, and only affects external
      clients.

# Resources
- https://gitlab.isc.org/isc-projects/kea-docker/-/tree/master/kea-compose?ref_type=heads
- https://kb.isc.org/docs/experimenting-with-postgresql-high-availability#summary-of-results
- https://www.postgresql.org/message-id/flat/17760-b6c61e752ec07060%40postgresql.org
- https://www.vanwerkhoven.org/blog/2024/vyos-from-scratch-with-vlan-and-zone-based-firewall/
- https://troopers.de/wp-content/uploads/2013/11/TROOPERS14-HA_Strategies_in_IPv6_Networks-Ivan_Pepelnjak.pdf
- https://github.com/vyos/vyos-1x/pull/2638 - flowtables in named tables for zone-based firewall
- https://serverfault.com/questions/1033682/dhclient-is-sending-host-name-for-ipv4-but-not-ipv6
- https://datatracker.ietf.org/doc/html/draft-krishnaswamy-dnsop-dnssec-split-view-04
- https://www.rfc-editor.org/rfc/rfc8901.html
- https://vyos.dev/T7358 - presumably we'll have proper flowtables soon

## TODOS

- NIC passthrough
