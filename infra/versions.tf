terraform {
  backend "gcs" {
    bucket                      = "nevi-dev-root-tfstate"
    prefix                      = "homelab"
    impersonate_service_account = "root-tf@nevi-dev-root.iam.gserviceaccount.com"
  }
  required_providers {
    infra = {
      source = "nevivurn/infra"
    }
  }
}

provider "infra" {
  url     = "https://api.inf.nevi.network"
  ca_crt  = "../ansible/pki/caddy/ca.crt"
  tls_crt = "../ansible/pki/caddy/client-certs/client.crt"
  tls_key = "data/client.key"
}
