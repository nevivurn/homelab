#!/usr/bin/env python3

import sys
from typing import Generator
from dataclasses import dataclass, field

from yaml import safe_load
from dataclass_wizard import JSONWizard
from dataclass_wizard.v1.enums import KeyAction


@dataclass
class ConfigZoneTableIPv4:
    ipv4: str


@dataclass
class ConfigZoneTableIPv6:
    ipv6: str


type ConfigZoneTableRule = str | ConfigZoneTableIPv4 | ConfigZoneTableIPv6


@dataclass
class ConfigZoneTable:
    zones: list[str] = field(default_factory=list)
    config: list[str] = field(default_factory=list)
    rules: dict[int, list[ConfigZoneTableRule]] = field(default_factory=dict)

    def generate(self, zone_name: str, table_name: str) -> Generator[str]:
        for from_zone in self.zones:
            yield f'zone {zone_name} from {from_zone} firewall name {table_name}'
            yield f'zone {zone_name} from {from_zone} firewall ipv6-name {table_name}'

        for line in self.config:
            yield f'ipv4 name {table_name} {line}'
            yield f'ipv6 name {table_name} {line}'

        for rule_id, rule_def in self.rules.items():
            for rule in rule_def:
                if isinstance(rule, str):
                    yield f'ipv4 name {table_name} rule {rule_id} {rule}'
                    yield f'ipv6 name {table_name} rule {rule_id} {rule}'
                elif isinstance(rule, ConfigZoneTableIPv4):
                    yield f'ipv4 name {table_name} rule {rule_id} {rule.ipv4}'
                elif isinstance(rule, ConfigZoneTableIPv6):
                    yield f'ipv6 name {table_name} rule {rule_id} {rule.ipv6}'
                else:
                    raise TypeError(rule)


@dataclass
class ConfigZone:
    members: list[str] = field(default_factory=list)
    config: list[str] = field(default_factory=list)
    tables: dict[str, ConfigZoneTable] = field(default_factory=dict)

    def generate(self, zone_name: str) -> Generator[str]:
        for member in self.members:
            yield f'zone {zone_name} member interface {member}'

        for line in self.config:
            yield f'zone {zone_name} {line}'

        for table_name, table in self.tables.items():
            yield from table.generate(zone_name, table_name)


@dataclass
class Configuration(JSONWizard):
    config: list[str] = field(default_factory=list)
    zones: dict[str, ConfigZone] = field(default_factory=dict)

    class _(JSONWizard.Meta):
        v1 = True
        v1_unsafe_parse_dataclass_in_union = True
        v1_on_unknown_key = KeyAction.RAISE

    def generate(self) -> Generator[str]:
        for line in self.config:
            yield f'set firewall {line}'

        for zone_name, zone in self.zones.items():
            for cfg in zone.generate(zone_name):
                yield f'set firewall {cfg}'


def main() -> None:
    if len(sys.argv) != 2:
        print(f'usage: {sys.argv[0]} <config.yaml>')
        sys.exit(1)

    with open(sys.argv[1]) as f:
        config_dict = safe_load(f)
    config = Configuration.from_dict(config_dict)
    assert isinstance(config, Configuration)

    for line in config.generate():
        print(line)


if __name__ == '__main__':
    main()
