{
  imports = [ ./common.nix ];
  primary = true;

  vyosConfig = {
    system.host-name = "rtr01";
  };
}
