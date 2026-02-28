{
  config,
  ...
}:

{
  vyosConfig.service.dns.dynamic.name.PUBLIC = {
    address.interface = "eth0.99";
    host-name = if config.primary then "rtr01.pub.nevi.network" else "rtr02.pub.nevi.network";
    ip-version = "both";
    protocol = "cloudflare";
    zone = "nevi.network";
  };
}
