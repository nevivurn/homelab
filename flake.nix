{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
        inherit (pkgs) callPackage;
      in
      {
        packages = {
          hosts = callPackage ./pkgs/hosts { };
          isc-dhcp-image = pkgs.isc-dhcp.passthru.image;
          chrony-image = pkgs.chrony.passthru.image;
          patroni-image = pkgs.patroni.passthru.image;
        };
        devShells.default = callPackage ./shell.nix { };
      }
    )
    // {
      overlays.default = final: prev: {
        isc-dhcp = final.callPackage ./pkgs/isc-dhcp { };
        chrony = prev.chrony.overrideAttrs (prevAttrs: {
          passthru = prevAttrs.passthru // {
            image = final.callPackage ./pkgs/chrony/image.nix { };
          };
        });
        patroni = prev.patroni.overrideAttrs (prevAttrs: {
          passthru = prevAttrs.passthru // {
            image = final.callPackage ./pkgs/patroni/image.nix { };
          };
        });
      };
    };
}
