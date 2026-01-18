locals {
  default_ttl = 60
  nameservers = [
    "net01.inf.nevi.network.",
    "net02.inf.nevi.network.",
  ]
  soa_email = "nevivurn.nevi.network."

  dns_zones = {
    fwd_root    = "nevi.network."
    rev_v4_root = "64.10.in-addr.arpa."
    rev_v6_root = "e.d.8.3.a.6.a.b.c.b.d.f.ip6.arpa."

    fwd_home  = "home.nevi.network."
    fwd_guest = "guest.nevi.network."
    fwd_inf   = "inf.nevi.network."
    fwd_k8s   = "k8s.nevi.network."

    rev_v4_home  = "10.64.10.in-addr.arpa."
    rev_v4_guest = "11.64.10.in-addr.arpa."
    rev_v4_inf   = "20.64.10.in-addr.arpa."
    rev_v4_k8s   = "30.64.10.in-addr.arpa."

    rev_v6_home  = "0.1.0.0.e.d.8.3.a.6.a.b.c.b.d.f.ip6.arpa."
    rev_v6_guest = "1.1.0.0.e.d.8.3.a.6.a.b.c.b.d.f.ip6.arpa."
    rev_v6_inf   = "0.2.0.0.e.d.8.3.a.6.a.b.c.b.d.f.ip6.arpa."
    rev_v6_k8s   = "0.3.0.0.e.d.8.3.a.6.a.b.c.b.d.f.ip6.arpa."
  }

  dns_roots = ["fwd_root", "rev_v4_root", "rev_v6_root"]

  dns_delegations = {
    fwd_root    = ["fwd_home", "fwd_guest", "fwd_inf", "fwd_k8s"]
    rev_v4_root = ["rev_v4_home", "rev_v4_guest", "rev_v4_inf", "rev_v4_k8s"]
    rev_v6_root = ["rev_v6_home", "rev_v6_guest", "rev_v6_inf", "rev_v6_k8s"]
  }
}
