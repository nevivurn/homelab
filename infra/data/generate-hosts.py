#!/usr/bin/env python3

import ipaddress
import json
import sys
import yaml


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

    for zone_name, zone_data in data.get("zones", {}).items():
        fwd_zone = zone_data.get("fwd")
        rev_v4_zone = zone_data.get("rev_v4")
        rev_v6_zone = zone_data.get("rev_v6")

        hosts = {}
        for host_name, host_data in zone_data.get("hosts", {}).items():
            host = {}

            if "ipv4" in host_data:
                addr = ipaddress.IPv4Address(host_data["ipv4"])
                host["ipv4"] = str(addr)
                host["ptr_v4"] = addr.reverse_pointer + "."

            if "ipv6" in host_data:
                addr = ipaddress.IPv6Address(host_data["ipv6"])
                host["ipv6"] = str(addr)
                host["ptr_v6"] = addr.reverse_pointer + "."

            hosts[host_name] = host

        output["hosts"][zone_name] = {
            "fwd": fwd_zone,
            "rev_v4": rev_v4_zone,
            "rev_v6": rev_v6_zone,
            "hosts": hosts,
        }

        output["records"][zone_name] = zone_data.get("records", {})

    json.dump(output, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
