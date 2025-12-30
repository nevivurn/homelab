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
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) callPackage;
      in
      {
        formatter = pkgs.nixfmt-tree;
        packages = {
          hosts = callPackage ./pkgs/hosts { };
          talosctl = pkgs.talosctl.overrideAttrs rec {
            version = "1.12.0";
            src = pkgs.fetchFromGitHub {
              owner = "siderolabs";
              repo = "talos";
              tag = "v${version}";
              hash = "sha256-u8/T01PWBGH3bJCNoC+FIzp8aH05ci4Kr3eHHWPDRkI=";
            };
            vendorHash = "sha256-LLtbdKq028EEs8lMt3uiwMo2KMJ6nJKf6xFyLJlg+oM=";
          };
        };
        devShells.default = callPackage ./shell.nix { inherit (self.packages.${system}) talosctl; };
      }
    );
}
