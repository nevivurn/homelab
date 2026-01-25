{ lib, pkgs }:

let
  libVyos = import ./lib { inherit lib; };
in

lib.pipe (builtins.readDir ./systems) [
  lib.attrNames
  (lib.filter (lib.hasSuffix ".nix"))
  (lib.flip lib.genAttrs' (f: {
    name = lib.removeSuffix ".nix" f;
    value = f;
  }))
  (lib.mapAttrs (_: m: libVyos.mkVyosConfig { modules = [ ./systems/${m} ]; }))
  (lib.mapAttrs (_: cfg: libVyos.toVyosCommands cfg.config.vyosConfig))
  (lib.mapAttrs (name: pkgs.writeText "${name}.txt"))
  (cfgs: pkgs.linkFarmFromDrvs "vyos-configs" (lib.attrValues cfgs))
]
