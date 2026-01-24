{
  imports = [ ./common.nix ];
  primary = false;

  vyosConfig = {
    system.host-name = "rtr01";
  };
}
