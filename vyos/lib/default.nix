{ lib }:

let
  libVyos = { inherit mkVyosConfig toVyosCommands listToVyosAttrs; };

  listToVyosAttrs = list: lib.genAttrs list (_: { });

  mkVyosConfig =
    { modules }:
    lib.evalModules {
      specialArgs = { inherit libVyos; };
      modules = [ ../modules ] ++ modules;
    };

  toVyosCommands =
    cfg:
    let
      toCommands =
        path: value:
        if lib.isAttrs value then
          if value == { } then
            [ "set ${lib.concatStringsSep " " path}" ]
          else
            lib.concatMap (key: toCommands (path ++ [ key ]) value.${key}) (lib.attrNames value)
        else
          [ "set ${lib.concatStringsSep " " (path ++ [ (builtins.toString value) ])}" ];
    in
    lib.concatLines (toCommands [ ] cfg);
in
libVyos
