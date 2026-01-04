package main

import (
	"context"
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"

	"github.com/nevivurn/homelab/pkgs/terraform-provider-infra/internal/provider"
)

func main() {
	var debug bool
	flag.BoolVar(&debug, "debug", false, "")
	flag.Parse()

	err := providerserver.Serve(context.Background(), provider.New, providerserver.ServeOpts{
		Address: "registry.terraform.io/nevivurn/infra",
		Debug:   debug,
	})
	if err != nil {
		log.Fatal(err)
	}
}
