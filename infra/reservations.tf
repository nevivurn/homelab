locals {
  all_reservations = { for k, v in local.all_hosts : k => v if lookup(v, "hw_address", null) != null }
}

resource "infra_dhcp4_reservation" "reservation" {
  for_each = local.all_reservations

  subnet_id  = each.value.subnet_id
  hw_address = each.value.hw_address
  ip_address = each.value.ipv4
  hostname   = each.value.host_name
}

resource "infra_dhcp6_reservation" "reservation" {
  for_each = local.all_reservations

  subnet_id  = each.value.subnet_id
  hw_address = each.value.hw_address
  ip_address = each.value.ipv6
  hostname   = each.value.host_name
}
