{
  lib,
  config,
  ...
}:

let
  cfg = config.firewall;

  groupsConfig = {
    firewall.group = {
      address-group = lib.mapAttrs (_: addrs: {
        address = addrs;
      }) cfg.groups.address-group;
      ipv6-address-group = lib.mapAttrs (_: addrs: {
        address = addrs;
      }) cfg.groups.ipv6-address-group;
      port-group = lib.mapAttrs (_: ports: { port = ports; }) cfg.groups.port-group;
    };
  };

  zonesConfig = {
    firewall.zone = lib.mapAttrs (
      name: zone:
      lib.filterAttrs (_: v: v != null) {
        member = if zone.members != [ ] then { interface = zone.members; } else null;
        local-zone = if zone.local-zone then { } else null;
        intra-zone-filtering = if !zone.local-zone then { action = zone.intra-zone-filtering; } else null;
      }
    ) cfg.zones;
  };

  generateTableRules =
    family: tableName: table:
    let
      transformRule =
        rule:
        let
          common = lib.removeAttrs rule [
            "ipv4"
            "ipv6"
          ];
        in
        lib.recursiveUpdate common rule.${family};

      vyosRules = lib.pipe table.rules [
        (lib.mapAttrs (_: transformRule))
        (lib.filterAttrs (_: r: r != { }))
      ];

    in
    lib.filterAttrs (_: v: v != null) {
      default-action = table.default-action;
      default-log = if table.default-action != "accept" then { } else null;
      rule = if vyosRules != { } then vyosRules else null;
    };

  tablesConfig = {
    firewall.ipv4.name = lib.mapAttrs (generateTableRules "ipv4") cfg.tables;
    firewall.ipv6.name = lib.mapAttrs (generateTableRules "ipv6") cfg.tables;
  };

  mappingsConfig.firewall.zone =
    let
      toMapping = src: dest: table: {
        ${dest}.from.${src}.firewall = {
          name = table;
          ipv6-name = table;
        };
      };
    in
    lib.foldlAttrs (
      acc: src: dests:
      lib.foldlAttrs (
        acc': dest: table:
        lib.recursiveUpdate acc' (toMapping src dest table)
      ) acc dests
    ) { } cfg.mappings;
in
{
  options.firewall = {
    groups = {
      address-group = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
      };
      ipv6-address-group = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
      };
      port-group = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
      };
    };

    zones = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            members = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            local-zone = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            intra-zone-filtering = lib.mkOption {
              type = lib.types.enum [
                "accept"
                "drop"
              ];
              default = "accept";
            };
          };
        }
      );
      default = { };
    };

    tables = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            default-action = lib.mkOption {
              type = lib.types.enum [
                "accept"
                "drop"
                "reject"
              ];
            };
            rules = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  freeformType = lib.types.attrs;
                  options = {
                    ipv4 = lib.mkOption {
                      type = lib.types.attrs;
                      default = { };
                    };
                    ipv6 = lib.mkOption {
                      type = lib.types.attrs;
                      default = { };
                    };
                  };
                }
              );
              default = { };
            };
          };
        }
      );
      default = { };
    };

    mappings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
    };
  };

  config.vyosConfig = lib.mkMerge [
    groupsConfig
    zonesConfig
    tablesConfig
    mappingsConfig
  ];
}
