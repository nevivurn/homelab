resource "infra_dns_zone" "zones" {
  for_each = local.dns_zones

  name        = each.value
  dnssec      = true
  nsec3param  = "1 0 0 -"
  nsec3narrow = true
}

resource "infra_dns_record" "zone_soa" {
  for_each = local.dns_zones

  zone    = infra_dns_zone.zones[each.key].name
  name    = infra_dns_zone.zones[each.key].name
  type    = "SOA"
  ttl     = local.default_ttl
  records = ["${local.nameservers[0]} ${local.soa_email} 2026011800 86400 7200 3600000 60"]

  lifecycle {
    ignore_changes = [records]
  }
}

resource "infra_dns_record" "zone_ns" {
  for_each = local.dns_zones

  zone    = infra_dns_zone.zones[each.key].name
  name    = infra_dns_zone.zones[each.key].name
  type    = "NS"
  ttl     = local.default_ttl
  records = local.nameservers
}

locals {
  zone_delegations = merge([
    for parent, children in local.dns_delegations : {
      for child in children : "${parent}/${child}" => {
        parent = parent
        child  = child
      }
    }
  ]...)
}

resource "infra_dns_record" "delegation_ns" {
  for_each = local.zone_delegations

  zone    = infra_dns_zone.zones[each.value.parent].name
  name    = infra_dns_zone.zones[each.value.child].name
  type    = "NS"
  ttl     = local.default_ttl
  records = local.nameservers
}

data "infra_dns_zone_ds" "delegated" {
  for_each = local.zone_delegations

  zone = infra_dns_zone.zones[each.value.child].name
}

resource "infra_dns_record" "delegation_ds" {
  for_each = local.zone_delegations

  zone    = infra_dns_zone.zones[each.value.parent].name
  name    = infra_dns_zone.zones[each.value.child].name
  type    = "DS"
  ttl     = local.default_ttl
  records = data.infra_dns_zone_ds.delegated[each.key].ds
}
