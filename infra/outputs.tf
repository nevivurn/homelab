output "fwd_root_ds" {
  value = { for zone in local.dns_roots : infra_dns_zone.zones[zone].name => data.infra_dns_zone_ds.dns_roots[zone].ds }
}

data "infra_dns_zone_ds" "dns_roots" {
  for_each = toset(local.dns_roots)

  zone = infra_dns_zone.zones[each.value].name
}
