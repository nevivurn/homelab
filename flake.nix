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
        inherit (nixpkgs) lib;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
        inherit (pkgs) callPackage;
      in
      {
        formatter = pkgs.nixfmt-tree;
        packages = {
          hosts = callPackage ./pkgs/hosts { };
          terraform-provider-infra = pkgs.terraform-providers.infra;
          vyos-configs = import ./vyos { inherit lib pkgs; };
        };
        devShells.default = callPackage ./shell.nix {
          customPackages = lib.attrValues self.packages.${system};
        };
      }
    )
    // {
      overlays.default = final: prev: {
        # custom packages
        terraform-providers = prev.terraform-providers // {
          infra = final.callPackage ./pkgs/terraform-provider-infra { };
        };
      };
    };
}
