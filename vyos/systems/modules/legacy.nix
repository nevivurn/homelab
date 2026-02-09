{ lib, ... }:

let
  routerv4 = "10.64.200.3";
  routerv6 = "fdbc:ba6a:38de:200::3";
  routev4 = [ "192.168.2.0/24" ];
  routev6 = [ "fdbc:ba6a:38de::/64" ];
in
{
  vyosConfig.protocols.static = {
    route = lib.genAttrs routev4 (r: {
      next-hop = routerv4;
    });
    route6 = lib.genAttrs routev6 (r: {
      next-hop = routerv6;
    });
  };
}
