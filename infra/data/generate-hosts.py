#!/usr/bin/env python3

import ipaddress
import sys
import yaml


def process_host(host_data):
    host = {}

    if "hw_address" in host_data:
        host["hw_address"] = host_data["hw_address"]

    if "ipv4" in host_data:
        addr = ipaddress.IPv4Address(host_data["ipv4"])
        host["ipv4"] = str(addr)
        host["ptr_v4"] = addr.reverse_pointer + "."

    if "ipv6" in host_data:
        addr = ipaddress.IPv6Address(host_data["ipv6"])
        host["ipv6"] = str(addr)
        host["ptr_v6"] = addr.reverse_pointer + "."

    if "ipv4s" in host_data:
        addrs = [ipaddress.IPv4Address(ip) for ip in host_data["ipv4s"]]
        host["ipv4s"] = [str(addr) for addr in addrs]
        host["ptrs_v4"] = [addr.reverse_pointer + "." for addr in addrs]

    if "ipv6s" in host_data:
        addrs = [ipaddress.IPv6Address(ip) for ip in host_data["ipv6s"]]
        host["ipv6s"] = [str(addr) for addr in addrs]
        host["ptrs_v6"] = [addr.reverse_pointer + "." for addr in addrs]

    return host


def main():
    data = yaml.safe_load(sys.stdin)

    output = {
        "hosts": {},
        "records": {},
    }

    for zone_name, zone_data in data.items():
        hosts = {}
        for host_name, host_data in zone_data.get("hosts", {}).items():
            hosts[host_name] = process_host(host_data)

        zone_output = {
            "fwd": zone_data.get("fwd"),
            "rev_v4": zone_data.get("rev_v4"),
            "rev_v6": zone_data.get("rev_v6"),
            "hosts": hosts,
        }

        if "subnet_id" in zone_data:
            zone_output["subnet_id"] = zone_data["subnet_id"]

        output["hosts"][zone_name] = zone_output
        output["records"][zone_name] = zone_data.get("records", {})

    yaml.dump(output, sys.stdout, default_flow_style=False, sort_keys=False)


if __name__ == "__main__":
    main()
