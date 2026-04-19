{
  config,
  ...
}:

{
  vyosConfig.service.dns.dynamic.name =
    let
      cfg = {
        host-name = if config.primary then "rtr01.nevi.ing" else "rtr02.nevi.ing";
        protocol = "cloudflare";
        zone = "nevi.ing";
      };
    in
    {
      PUBLIC4 = cfg // {
        address.interface = "eth0.99";
        ip-version = "ipv4";
      };
      PUBLIC6 = cfg // {
        address.interface = "tun99";
        ip-version = "ipv6";
      };
    };
}
