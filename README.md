# homelab

## Addressing

Generally, everything is in `10.64.0.0/16` and `fdbc:ba6a:38de::/48`.

VLAN | Name                     | DNS                | IPv4           | IPv6
---  | ---                      | ---                | ---            | ---
1    | LEGACY                   | ---                | 192.168.0.0/22 | fdbc:ba6a:38de::/62
10   | HOME                     | home.nevi.network  | 10.64.10.0/24  | fdbc:ba6a:38de:10::/64
11   | GUEST                    | guest.nevi.network | 10.64.11.0/24  | fdbc:ba6a:38de:11::/64
20   | INFRA                    | inf.nevi.network   | 10.64.20.0/24  | fdbc:ba6a:38de:20::/64
30   | Kubernetes nodes         | k8s.nevi.network   | 10.64.30.0/24  | fdbc:ba6a:38de:30::/64
30   | Kubernetes loadbalancers | ---                | 10.64.31.0/24  | fdbc:ba6a:38de:31::/64
30   | Kubernetes pods          | ---                | 172.29.0.0/16  | fdbc:ba6a:38de:32::/64
---  | ClusterIPs               | svc.cluster.local  | 172.30.0.0/16  | fdbc:ba6a:38de:33::/64
200  | ROUTER                   |                    | 10.64.200.0/24 |

DHCP ranges are
- IPv4: `.100 ~ .200`
- IPv6: `:d6d6::/80`

### Reserved ranges

CIDR                | Notes
---                 | ---
10.42.42.0/24       | legacy vpn
10.42.43.0/24       | legacy proxy
10.89.0.0/16        | Bacchus internal range
10.90.0.0/16        | Bacchus internal range
10.91.0.0/16        | Bacchus internal range
10.92.0.0/16        | Bacchus internal range
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

### Infra subnet

Address | Host    | Notes
---     | ---     | ---
.1      | gateway | VRRP
.2      | rtr01   |
.3      | rtr02   |
.4      | net01   | DHCP, DNS, NTP
.5      | net02   | DHCP, DNS, NTP
.6      | net03   | quorum for net01, net02
.11     | pve01   |

### Other subnets

Address | Host    | Notes
---     | ---     | ---
.1      | gateway | VRRP
.2      | rtr01   |
.3      | rtr02   |
.4      | relay01 | DHCP relay to net01
.5      | relay02 | DHCP relay to net02

## Network Services

# Resources
- https://gitlab.isc.org/isc-projects/kea-docker/-/tree/master/kea-compose?ref_type=heads
- https://kb.isc.org/docs/experimenting-with-postgresql-high-availability#summary-of-results
