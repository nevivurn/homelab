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
        };
        devShells.default = callPackage ./shell.nix {
          customPackages = lib.attrValues self.packages.${system};
        };
      }
    )
    // {
      overlays.default = final: prev: {
        # ref: https://github.com/NixOS/nixpkgs/pull/473711
        # hasn't landed on unstable quite yet
        talosctl = prev.talosctl.overrideAttrs rec {
          version = "1.12.0";
          src = final.fetchFromGitHub {
            owner = "siderolabs";
            repo = "talos";
            tag = "v${version}";
            hash = "sha256-u8/T01PWBGH3bJCNoC+FIzp8aH05ci4Kr3eHHWPDRkI=";
          };
          vendorHash = "sha256-LLtbdKq028EEs8lMt3uiwMo2KMJ6nJKf6xFyLJlg+oM=";
        };

        # custom packages
        terraform-providers = prev.terraform-providers // {
          infra = final.callPackage ./pkgs/terraform-provider-infra { };
        };
      };
    };
}
