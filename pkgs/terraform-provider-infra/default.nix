{
  lib,
  terraform-providers,
}:

terraform-providers.mkProvider rec {
  owner = "nevivurn";
  repo = "terraform-provider-infra";
  provider-source-address = "registry.terraform.io/nevivurn/infra";

  spdx = "GPL-3.0-or-later";
  mkProviderFetcher = _: ./.;

  rev = "v1.0.0";
  version = lib.removePrefix "v" rev;

  hash = null;
  vendorHash = "sha256-z1qWykfTd00WTSyCtLnB793+rMiWDiK57/Kvq1EYbks=";
}
