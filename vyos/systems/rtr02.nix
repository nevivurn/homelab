{
  imports = [ ./modules ];
  primary = false;

  vyosConfig = {
    system.host-name = "rtr01";
  };
}
