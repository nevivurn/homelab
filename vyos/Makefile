.PHONY: all
all: generate

.PHONY: generate
generate: results

.PHONY: results
results:
	nix build .#vyos-configs
