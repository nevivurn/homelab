# temp. rendering testing harness
{ lib }:

let
  libVyos = import ./lib { inherit lib; };

  cfg = libVyos.mkVyosConfig {
    modules = [ ./systems/rtr01.nix ];
  };
in

libVyos.toVyosCommands cfg.config.vyosConfig
