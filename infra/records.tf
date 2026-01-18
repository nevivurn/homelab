locals {
  hosts_data = yamldecode(file("${path.module}/data/generated_hosts.yaml"))

  all_hosts = merge([
    for zone_name, zone_data in local.hosts_data.hosts : {
      for host_name, host_data in zone_data.hosts : "${zone_name}/${host_name}" => merge(host_data, {
        host_name = host_name
        fwd_zone  = zone_data.fwd
        rev_v4    = zone_data.rev_v4
        rev_v6    = zone_data.rev_v6
        subnet_id = lookup(zone_data, "subnet_id", null)
      })
    }
  ]...)

  custom_records = merge([
    for zone_name, records in local.hosts_data.records : merge([
      for host_name, host_data in records : {
        for rrtype, rrs in host_data : "${zone_name}/${host_name}/${rrtype}" => {
          zone_name = local.hosts_data.hosts[zone_name].fwd
          host_name = host_name
          type      = rrtype
          records   = rrs
        }
      }
    ]...)
  ]...)
}

resource "infra_dns_record" "host_a" {
  for_each = local.all_hosts

  zone    = infra_dns_zone.zones[each.value.fwd_zone].name
  name    = "${each.value.host_name}.${infra_dns_zone.zones[each.value.fwd_zone].name}"
  type    = "A"
  ttl     = local.default_ttl
  records = [each.value.ipv4]
}

resource "infra_dns_record" "host_aaaa" {
  for_each = local.all_hosts

  zone    = infra_dns_zone.zones[each.value.fwd_zone].name
  name    = "${each.value.host_name}.${infra_dns_zone.zones[each.value.fwd_zone].name}"
  type    = "AAAA"
  ttl     = local.default_ttl
  records = [each.value.ipv6]
}

resource "infra_dns_record" "host_ptr_v4" {
  for_each = local.all_hosts

  zone    = infra_dns_zone.zones[each.value.rev_v4].name
  name    = each.value.ptr_v4
  type    = "PTR"
  ttl     = local.default_ttl
  records = ["${each.value.host_name}.${infra_dns_zone.zones[each.value.fwd_zone].name}"]
}

resource "infra_dns_record" "host_ptr_v6" {
  for_each = local.all_hosts

  zone    = infra_dns_zone.zones[each.value.rev_v6].name
  name    = each.value.ptr_v6
  type    = "PTR"
  ttl     = local.default_ttl
  records = ["${each.value.host_name}.${infra_dns_zone.zones[each.value.fwd_zone].name}"]
}

resource "infra_dns_record" "custom_record" {
  for_each = local.custom_records

  zone    = infra_dns_zone.zones[each.value.zone_name].name
  name    = "${each.value.host_name}.${infra_dns_zone.zones[each.value.zone_name].name}"
  type    = each.value.type
  ttl     = local.default_ttl
  records = each.value.records
}


