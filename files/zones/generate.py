#!/usr/bin/env python3

import sys
from typing import Protocol, TypeVar
from abc import abstractmethod
from dataclasses import dataclass
from ipaddress import IPv4Address, IPv4Network, IPv6Address, IPv6Network

from yaml import safe_load
from dataclass_wizard import JSONWizard
from dataclass_wizard.v1 import Alias
from dataclass_wizard.v1.enums import KeyAction


@dataclass
class ConfigFwdHost:
    ipv4: str | None = None
    ipv6: str | None = None


@dataclass
class ConfigFwdZone:
    hosts: dict[str, ConfigFwdHost]


@dataclass
class ConfigRevZone:
    ipv4: list[str]
    ipv6: list[str]


@dataclass
class Configuration(JSONWizard):
    nameservers: list[str]
    soa: str
    ttl: int
    forward_zones: dict[str, ConfigFwdZone] = Alias('forward-zones')
    reverse_zones: ConfigRevZone = Alias('reverse-zones')

    class _(JSONWizard.Meta):
        v1 = True
        v1_unsafe_parse_dataclass_in_union = True
        v1_on_unknown_key = KeyAction.RAISE


def generate_fwd(cfg: Configuration, zone_name: str, zone: ConfigFwdZone, rev_v4: dict[str, str], rev_v6: dict[str, str]) -> None:
    with open(f'hosts/{zone_name}.zone', 'w') as f:
        print(f'$ORIGIN {zone_name}', file=f)
        print(f'$TTL {cfg.ttl}', file=f)

        print(f'@ SOA {cfg.nameservers[0]}. {cfg.soa}', file=f)
        for ns in cfg.nameservers:
            print(f'@ NS {ns}.', file=f)

        for name, host in zone.hosts.items():
            if host.ipv4:
                print(f'{name} A {host.ipv4}', file=f)
                rev_v4[host.ipv4] = f'{name}.{zone_name}'
            if host.ipv6:
                print(f'{name} AAAA {host.ipv6}', file=f)
                rev_v6[host.ipv6] = f'{name}.{zone_name}'


class Address(Protocol):
    @property
    def reverse_pointer(self) -> str:
        ...


T = TypeVar('T', bound=Address)


class Network[T](Protocol):
    @property
    def network_address(self) -> T:
        ...

    @property
    def prefixlen(self) -> int:
        ...

    @abstractmethod
    def __contains__(self, other: T) -> bool:
        ...


def generate_rev(cfg: Configuration, prefix_rev: str, prefix: Network[T], rev: dict[T, str]) -> None:
    with open(f'hosts/{prefix_rev}.zone', 'w') as f:
        print(f'$ORIGIN {prefix_rev}', file=f)
        print(f'$TTL {cfg.ttl}', file=f)
        print(f'@ SOA {cfg.nameservers[0]}. {cfg.soa}', file=f)
        for ns in cfg.nameservers:
            print(f'@ NS {ns}.', file=f)
        for addr, name in rev.items():
            if addr not in prefix:
                continue
            print(f'{addr.reverse_pointer}. PTR {name}.', file=f)


def generate_rev_v4(cfg: Configuration, prefixes: list[str], rev: dict[str, str]) -> None:
    rev_addr = {IPv4Address(k): v for k, v in rev.items()}
    for prefix in prefixes:
        prefix_net = IPv4Network(prefix)
        prefix_rev = prefix_net.network_address.reverse_pointer
        prefix_rev = '.'.join(prefix_rev.split('.')[(32 - prefix_net.prefixlen) // 8:])
        generate_rev(cfg, prefix_rev, prefix_net, rev_addr)


def generate_rev_v6(cfg: Configuration, prefixes: list[str], rev: dict[str, str]) -> None:
    rev_addr = {IPv6Address(k): v for k, v in rev.items()}
    for prefix in prefixes:
        prefix_net = IPv6Network(prefix)
        prefix_rev = prefix_net.network_address.reverse_pointer
        prefix_rev = '.'.join(prefix_rev.split('.')[(128 - prefix_net.prefixlen) // 4:])
        generate_rev(cfg, prefix_rev, prefix_net, rev_addr)


def generate(cfg: Configuration) -> None:
    rev_v4: dict[str, str] = {}
    rev_v6: dict[str, str] = {}
    for name, zone in cfg.forward_zones.items():
        generate_fwd(cfg, name, zone, rev_v4, rev_v6)
    generate_rev_v4(cfg, cfg.reverse_zones.ipv4, rev_v4)
    generate_rev_v6(cfg, cfg.reverse_zones.ipv6, rev_v6)


def main() -> None:
    if len(sys.argv) != 2:
        print(f'usage: {sys.argv[0]} <config.yaml>')
        sys.exit(1)

    with open(sys.argv[1]) as f:
        config_dict = safe_load(f)
    config = Configuration.from_dict(config_dict)
    assert isinstance(config, Configuration)

    generate(config)


if __name__ == '__main__':
    main()
