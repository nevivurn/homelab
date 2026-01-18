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

    return host


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <hosts.yaml>", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1], 'r') as f:
        data = yaml.safe_load(f)

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
