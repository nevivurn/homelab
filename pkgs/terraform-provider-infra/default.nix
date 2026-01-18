{
  lib,
  terraform-providers,
}:

terraform-providers.mkProvider rec {
  owner = "nevivurn";
  repo = "terraform-provider-infra";
  provider-source-address = "registry.terraform.io/nevivurn/infra";

  spdx = "GPL-3.0-or-later";
  mkProviderFetcher = lib.const ./.;

  rev = "v1.0.0";
  version = lib.removePrefix "v" rev;

  hash = null;
  vendorHash = "sha256-GHlpjdSyvr3KZ+0bs2sEFV3zkHVnq/cmzlDyBEH540o=";
}
