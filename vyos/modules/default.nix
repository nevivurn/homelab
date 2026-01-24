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
        mergeValue =
          path: lhs: rhs:
          if lib.isString lhs && lib.isString rhs then
            {
              ${lhs} = { };
              ${rhs} = { };
            }
          else if lib.isString lhs && lib.isAttrs rhs then
            { ${lhs} = { }; } // rhs
          else if lib.isAttrs lhs && lib.isString rhs then
            lhs // { ${rhs} = { }; }
          else if lib.isAttrs lhs && lib.isAttrs rhs then
            let
              allKeys = lib.uniqueStrings (lib.attrNames lhs ++ lib.attrNames rhs);
              mergeKey =
                k:
                if lhs ? ${k} && rhs ? ${k} then
                  mergeValue (path ++ [ k ]) lhs.${k} rhs.${k}
                else if lhs ? ${k} then
                  lhs.${k}
                else
                  rhs.${k};
            in
            lib.genAttrs allKeys mergeKey
          else
            rhs;
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
