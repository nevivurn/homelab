{ lib, ... }:

let
  allModules = lib.pipe (builtins.readDir ./.) [
    lib.attrNames
    (lib.filter (f: f != "default.nix"))
    (lib.map (f: ./${f}))
  ];

  vyosType = lib.types.mkOptionType {
    name = "vyosConfig";
    merge =
      loc: defs:
      let
        normalValue =
          v:
          if lib.isAttrs v then
            v
          else if lib.isString v then
            { ${v} = { }; }
          else if lib.isList v then
            lib.genAttrs v (_: { })
          else
            throw "invalid type";

        mergeValue =
          path: lhs: rhs:
          let
            lhs' = normalValue lhs;
            rhs' = normalValue rhs;
            allKeys = lib.uniqueStrings (lib.attrNames lhs' ++ lib.attrNames rhs');
            mergeKey =
              k:
              if lhs' ? ${k} && rhs' ? ${k} then
                mergeValue (path ++ [ k ]) lhs'.${k} rhs'.${k}
              else if lhs' ? ${k} then
                lhs'.${k}
              else
                rhs'.${k};
          in
          lib.genAttrs allKeys mergeKey;
      in
      lib.foldl' (acc: def: mergeValue loc acc def.value) { } defs;
  };
in

{
  imports = allModules;

  options.vyosConfig = lib.mkOption {
    type = lib.types.submodule {
      freeformType = vyosType;
    };
    default = { };
  };
}
