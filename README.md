# homelab

## Addressing

Generally, most networks are in `10.64.0.0/16` and `fdbc:ba6a:38de::/48`.

VLAN | Name                     | DNS                | IPv4           | IPv6
---  | ---                      | ---                | ---            | ---
1    | MGMT                     | mgmt.nevi.network  | 10.64.1.0/24   | fdbc:ba6a:38de:1::/64
10   | HOME                     | home.nevi.network  | 10.64.10.0/24  | fdbc:ba6a:38de:10::/64
10   | wg40 (rtr01)             |                    | 10.64.41.0/24  | fdbc:ba6a:38de:41::/64
10   | wg40 (rtr02)             |                    | 10.64.42.0/24  | fdbc:ba6a:38de:42::/64
N/A  | wg50 (rtr01)             | prx.nevi.network   | 10.64.51.0/24  | fdbc:ba6a:38de:51::/64
N/A  | wg50 (rtr02)             | prx.nevi.network   | 10.64.52.0/24  | fdbc:ba6a:38de:52::/64
11   | GUEST                    | guest.nevi.network | 10.64.11.0/24  | fdbc:ba6a:38de:11::/64
20   | INFRA                    | inf.nevi.network   | 10.64.20.0/24  | fdbc:ba6a:38de:20::/64
30   | Kubernetes nodes         | k8s.nevi.network   | 10.64.30.0/24  | fdbc:ba6a:38de:30::/64
30   | Kubernetes loadbalancers | ---                | 10.64.31.0/24  | fdbc:ba6a:38de:31::/64
30   | Kubernetes pods          | ---                | 10.32.0.0/16   | fdbc:ba6a:38de:32::/64
200  | ROUTER                   |                    | 10.64.200.0/24 | fdbc:ba6a:38de:200::/64

DHCP ranges are
- IPv4: `.100 ~ .200`
- IPv6: `:d6d6::/80`

### Reserved ranges

CIDR                      | Notes
---                       | ---
172.20.0.0/14             | dn42
10.96.0.0/12              | shared talos default service range
fdbc:ba6a:38de:6000::/108 | shared service range

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

Address | Host    | Notes
---     | ---     | ---
.1      | gateway | VRRP
.2      | rtr01   |
.3      | rtr02   |
.4      | net01   | DHCP, DNS, NTP
.5      | net02   | DHCP, DNS, NTP
.6      | net03   | quorum
.7      | relay01 | DHCP relay to net01
.8      | relay02 | DHCP relay to net02

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

Cluster | Endpoint | CP        | Worker     | Pods          | LBs
---     |          | ---       | ---        | ---           | ---
capi    | .10      | .10       |            | 10.32.0.0/20  | 10.64.31.0/28
C20     | .20      | .21 ~ .24 | .101 ~ 109 | 10.32.16.0/20 | 10.64.31.16/28
C25     | .25      | .26 ~ .29 | .101 ~ 109 | 10.32.32.0/20 | 10.64.31.32/28
C30     | .30      | .31 ~ .34 | .111 ~ 119 | 10.32.48.0/20 | 10.64.31.48/28
C35     | .35      | .36 ~ .39 | .111 ~ 119 | 10.32.64.0/20 | 10.64.31.64/28

- There is no DHCP service in the K8S zone
- ipv4 loadbalancer range assigned in blocks of /27
- ipv6 loadbalancer range assigned in blocks of /112
- ipv4 pod range assigned in blocks of /20 (/24 per node) starting from 10.32.0.0/20
- ipv6 pod range assigned in blocks of /80 (/96 per node) starting from fdbc:ba6a:38de:32::/80
- non-service clusters (pod IP masquerade, no BGP, etc.) use the shared ranges
  as documented in `Reserved Ranges`.

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
- https://a-cup-of.coffee/blog/talos-capi-proxmox/
- Turns out naive passthrough hurts performance vs. paravirt NICs, and I can't
  be bothered to figure it out over a <10% performance hit over line rate. I'll
  fix it when we upgrade to >10Gbit networking. By that time, I'll presumably
  have switched to physical routers.

## TODOs

- ntp with gps
- aqi
